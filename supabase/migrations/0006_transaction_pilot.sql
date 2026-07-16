begin;

create extension if not exists btree_gist;

create table public.job_quotes (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  provider_id uuid not null references public.providers(id),
  provider_service_id uuid not null references public.provider_services(id),
  amount bigint not null check (amount > 0),
  duration_minutes integer not null check (duration_minutes between 30 and 43200),
  message text not null,
  status text not null default 'submitted' check (status in ('submitted','accepted','declined','expired','withdrawn')),
  expires_at timestamptz not null,
  version integer not null default 1,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(job_id, provider_id, version)
);

alter table public.job_quotes enable row level security;
alter table public.bookings alter column scheduled_end set not null;
alter table public.bookings add constraint bookings_provider_time_excl
  exclude using gist (provider_id with =, tstzrange(scheduled_start, scheduled_end, '[)') with &&)
  where (status <> 'cancelled');

create sequence public.invoice_number_seq;

revoke update on public.jobs from authenticated;
revoke insert on public.jobs from authenticated;
grant update(title, description, requested_start, requested_end, budget_min, budget_max, address_id) on public.jobs to authenticated;
revoke insert, update on public.bookings from authenticated;
grant select on public.job_quotes to authenticated;

create policy jobs_matched_provider_read on public.jobs for select to authenticated using (
  exists (select 1 from public.job_matches m where m.job_id = jobs.id and private.is_provider_member(m.provider_id, null))
);
create policy matches_provider_read on public.job_matches for select to authenticated using (
  private.is_provider_member(provider_id, null)
);
create policy quotes_customer_read on public.job_quotes for select to authenticated using (
  exists (select 1 from public.jobs j where j.id = job_quotes.job_id and j.customer_id = (select auth.uid()))
);
create policy quotes_provider_read on public.job_quotes for select to authenticated using (
  private.is_provider_member(provider_id, null)
);

create or replace function private.reject_ledger_mutation()
returns trigger language plpgsql security definer set search_path = '' as $$
begin raise exception 'ledger rows are append-only' using errcode = '55000'; end;
$$;
create trigger ledger_transactions_append_only before update or delete on public.ledger_transactions
for each row execute function private.reject_ledger_mutation();
create trigger ledger_entries_append_only before update or delete on public.ledger_entries
for each row execute function private.reject_ledger_mutation();

create or replace function private.assert_ledger_transaction_balanced()
returns trigger language plpgsql security definer set search_path = '' as $$
declare target_transaction_id uuid;
begin
  if tg_op = 'DELETE' then target_transaction_id := old.transaction_id; else target_transaction_id := new.transaction_id; end if;
  if (select coalesce(sum(amount), 0) from public.ledger_entries where transaction_id = target_transaction_id) <> 0 then
    raise exception 'ledger transaction % is not balanced', target_transaction_id using errcode = '23514';
  end if;
  return null;
end;
$$;
create constraint trigger ledger_transaction_balanced
after insert or update or delete on public.ledger_entries deferrable initially deferred
for each row execute function private.assert_ledger_transaction_balanced();

create or replace function public.submit_job_request(
  p_service_id uuid, p_title text, p_description text,
  p_requested_start timestamptz, p_requested_end timestamptz,
  p_budget_min bigint, p_budget_max bigint, p_idempotency_key text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid()); new_job_id uuid; existing_id uuid;
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  select resource_id into existing_id from public.idempotency_keys where principal_id = actor_id and scope = 'job.create' and key = p_idempotency_key and expires_at > now();
  if existing_id is not null then return existing_id; end if;
  if length(trim(p_title)) < 5 or length(trim(p_description)) < 20 then raise exception 'job detail is incomplete' using errcode = '22023'; end if;
  if p_requested_start <= now() or p_requested_end <= p_requested_start then raise exception 'invalid requested window' using errcode = '22023'; end if;
  if p_budget_min < 0 or p_budget_max < p_budget_min then raise exception 'invalid budget' using errcode = '22023'; end if;

  insert into public.jobs(customer_id, service_id, title, description, booking_type, status, requested_start, requested_end, budget_min, budget_max)
  values (actor_id, p_service_id, trim(p_title), trim(p_description), 'scheduled', 'requested', p_requested_start, p_requested_end, p_budget_min, p_budget_max)
  returning id into new_job_id;

  insert into public.job_matches(job_id, provider_id, provider_service_id, rank, score, score_components, reason_codes, model_version, status)
  select new_job_id, ps.provider_id, ps.id,
    row_number() over (order by p.rating_avg desc, p.response_rate desc, p.id)::integer,
    least(1, (p.rating_avg / 5 * 0.6 + p.response_rate / 100 * 0.4))::numeric(8,5),
    jsonb_build_object('rating', p.rating_avg, 'response_rate', p.response_rate), array['service_match','verified_provider'], 'rules-v1', 'invited'
  from public.provider_services ps join public.providers p on p.id = ps.provider_id
  where ps.service_id = p_service_id and ps.status = 'active' and p.status = 'active' and p.verification_status = 'verified'
  order by p.rating_avg desc, p.response_rate desc limit 10;

  if exists (select 1 from public.job_matches where job_id = new_job_id) then update public.jobs set status = 'matched' where id = new_job_id; end if;
  insert into public.idempotency_keys(principal_id, scope, key, request_hash, response_status, resource_id, expires_at)
  values (actor_id, 'job.create', p_idempotency_key, pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(concat_ws('|',p_service_id,p_title,p_requested_start)::text,'UTF8')),'hex'), 201, new_job_id, now() + interval '24 hours');
  insert into public.outbox_events(aggregate_type, aggregate_id, event_type, payload, correlation_id)
  values ('job', new_job_id, 'job.requested', jsonb_build_object('job_id',new_job_id), p_idempotency_key);
  return new_job_id;
end;
$$;

create or replace function public.submit_job_quote(
  p_job_id uuid, p_provider_service_id uuid, p_amount bigint,
  p_duration_minutes integer, p_message text, p_expires_at timestamptz
) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid()); target_provider_id uuid; customer_user_id uuid; new_quote_id uuid; next_version integer;
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  select ps.provider_id into target_provider_id from public.provider_services ps where ps.id = p_provider_service_id and ps.status = 'active';
  if target_provider_id is null or not private.is_provider_member(target_provider_id, array['owner','manager']) then raise exception 'provider access denied' using errcode = '42501'; end if;
  select customer_id into customer_user_id from public.jobs where id = p_job_id and status in ('requested','matched') for update;
  if customer_user_id is null or not exists (select 1 from public.job_matches where job_id = p_job_id and provider_id = target_provider_id) then raise exception 'eligible job not found' using errcode = 'P0002'; end if;
  if p_amount <= 0 or p_duration_minutes < 30 or length(trim(p_message)) < 10 or p_expires_at <= now() then raise exception 'invalid quote' using errcode = '22023'; end if;
  select coalesce(max(version),0)+1 into next_version from public.job_quotes where job_id=p_job_id and provider_id=target_provider_id;
  update public.job_quotes set status='withdrawn', updated_at=now() where job_id=p_job_id and provider_id=target_provider_id and status='submitted';
  insert into public.job_quotes(job_id,provider_id,provider_service_id,amount,duration_minutes,message,expires_at,version,created_by)
  values(p_job_id,target_provider_id,p_provider_service_id,p_amount,p_duration_minutes,trim(p_message),p_expires_at,next_version,actor_id) returning id into new_quote_id;
  insert into public.notifications(user_id,event_type,channel,template_version,payload)
  values(customer_user_id,'quote.received','in_app','v1',jsonb_build_object('job_id',p_job_id,'quote_id',new_quote_id));
  return new_quote_id;
end;
$$;

create or replace function public.accept_quote_and_create_booking(
  p_quote_id uuid, p_scheduled_start timestamptz, p_idempotency_key text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid()); q public.job_quotes; j public.jobs; new_booking_id uuid; existing_id uuid; scheduled_finish timestamptz; fee bigint; total bigint; provider_owner uuid; new_conversation uuid;
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  select resource_id into existing_id from public.idempotency_keys where principal_id=actor_id and scope='booking.create' and key=p_idempotency_key and expires_at>now();
  if existing_id is not null then return existing_id; end if;
  select * into q from public.job_quotes where id=p_quote_id and status='submitted' and expires_at>now() for update;
  if q.id is null then raise exception 'active quote not found' using errcode = 'P0002'; end if;
  select * into j from public.jobs where id=q.job_id and customer_id=actor_id and status in ('requested','matched') for update;
  if j.id is null then raise exception 'job access denied' using errcode = '42501'; end if;
  if p_scheduled_start < j.requested_start or p_scheduled_start >= j.requested_end then raise exception 'schedule outside requested window' using errcode = '22023'; end if;
  scheduled_finish := p_scheduled_start + make_interval(mins => q.duration_minutes);
  if scheduled_finish > j.requested_end then raise exception 'schedule exceeds requested window' using errcode = '22023'; end if;
  if not exists (
    select 1 from public.provider_availability a
    where a.provider_id=q.provider_id and a.is_available
      and a.weekday=extract(dow from (p_scheduled_start at time zone 'Asia/Jakarta'))::smallint
      and a.starts_at <= (p_scheduled_start at time zone 'Asia/Jakarta')::time
      and a.ends_at >= (scheduled_finish at time zone 'Asia/Jakarta')::time
  ) then raise exception 'provider unavailable for selected schedule' using errcode='22023'; end if;
  fee := round(q.amount * 0.10); total := q.amount + fee;
  insert into public.bookings(job_id,customer_id,business_id,provider_id,provider_service_id,status,scheduled_start,scheduled_end,subtotal,platform_fee,tax_amount,total_amount,policy_snapshot)
  values(j.id,actor_id,j.business_id,q.provider_id,q.provider_service_id,'awaiting_payment',p_scheduled_start,scheduled_finish,q.amount,fee,0,total,jsonb_build_object('fee_rate',0.10,'quote_id',q.id,'quote_version',q.version)) returning id into new_booking_id;
  update public.job_quotes set status=case when id=q.id then 'accepted' else 'expired' end,updated_at=now() where job_id=j.id and status='submitted';
  update public.jobs set status='awaiting_payment',updated_at=now(),version=version+1 where id=j.id;
  insert into public.job_status_events(booking_id,from_status,to_status,actor_user_id,reason_code) values(new_booking_id,null,'awaiting_payment',actor_id,'quote_accepted');
  insert into public.payment_intents(booking_id,provider,status,amount,idempotency_key,expires_at)
  values(new_booking_id,'sandbox','pending',total,p_idempotency_key,now()+interval '30 minutes');
  insert into public.conversations(booking_id,kind) values(new_booking_id,'job') returning id into new_conversation;
  select owner_user_id into provider_owner from public.providers where id=q.provider_id;
  insert into public.conversation_participants(conversation_id,user_id,participant_role) values(new_conversation,actor_id,'customer'),(new_conversation,provider_owner,'provider');
  insert into public.idempotency_keys(principal_id,scope,key,request_hash,response_status,resource_id,expires_at)
  values(actor_id,'booking.create',p_idempotency_key,pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(concat_ws('|',p_quote_id,p_scheduled_start)::text,'UTF8')),'hex'),201,new_booking_id,now()+interval '24 hours');
  return new_booking_id;
exception when exclusion_violation then raise exception 'provider schedule conflict' using errcode='23P01';
end;
$$;

create or replace function public.capture_sandbox_payment(p_booking_id uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid()); b public.bookings; intent public.payment_intents; tx_id uuid; psp_account uuid; provider_account uuid; platform_account uuid; tax_account uuid; invoice_id uuid;
begin
  if actor_id is null then raise exception 'authentication required' using errcode='28000'; end if;
  select * into b from public.bookings where id=p_booking_id and customer_id=actor_id for update;
  if b.id is null then raise exception 'booking access denied' using errcode='42501'; end if;
  select * into intent from public.payment_intents where booking_id=b.id order by created_at desc limit 1 for update;
  if intent.status='captured' then return b.id; end if;
  if intent.status<>'pending' or intent.expires_at<=now() or intent.amount<>b.total_amount then raise exception 'payment intent invalid' using errcode='22023'; end if;
  if coalesce((select current_setting('app.environment',true)),'production')='production' then raise exception 'sandbox payment disabled in production' using errcode='42501'; end if;

  update public.payment_intents set status='captured',provider_reference='sandbox-'||id::text,updated_at=now(),version=version+1 where id=intent.id;
  insert into public.payment_holds(booking_id,payment_intent_id,amount,status) values(b.id,intent.id,b.total_amount,'held');
  insert into public.ledger_accounts(owner_type,owner_id,account_type,name) values('psp','00000000-0000-0000-0000-000000000001','asset','Sandbox PSP cash') on conflict(owner_type,owner_id,account_type,currency,name) do update set status='active' returning id into psp_account;
  insert into public.ledger_accounts(owner_type,owner_id,account_type,name) values('provider',b.provider_id,'liability','Provider payable') on conflict(owner_type,owner_id,account_type,currency,name) do update set status='active' returning id into provider_account;
  insert into public.ledger_accounts(owner_type,owner_id,account_type,name) values('platform','00000000-0000-0000-0000-000000000001','revenue','Platform fee') on conflict(owner_type,owner_id,account_type,currency,name) do update set status='active' returning id into platform_account;
  insert into public.ledger_accounts(owner_type,owner_id,account_type,name) values('tax','00000000-0000-0000-0000-000000000001','liability','Tax payable') on conflict(owner_type,owner_id,account_type,currency,name) do update set status='active' returning id into tax_account;
  insert into public.ledger_transactions(reference_type,reference_id,kind,description,created_by) values('payment_intent',intent.id,'payment_captured','Sandbox payment captured',actor_id) returning id into tx_id;
  insert into public.ledger_entries(transaction_id,account_id,amount) values(tx_id,psp_account,b.total_amount),(tx_id,provider_account,-b.subtotal),(tx_id,platform_account,-b.platform_fee);
  if b.tax_amount>0 then insert into public.ledger_entries(transaction_id,account_id,amount) values(tx_id,tax_account,-b.tax_amount); end if;

  update public.bookings set status='confirmed',updated_at=now(),version=version+1 where id=b.id;
  update public.jobs set status='confirmed',updated_at=now(),version=version+1 where id=b.job_id;
  insert into public.job_status_events(booking_id,from_status,to_status,actor_user_id,reason_code) values(b.id,'awaiting_payment','confirmed',actor_id,'payment_captured');
  insert into public.invoices(booking_id,business_id,invoice_number,status,subtotal,tax_amount,total_amount,billing_snapshot,tax_snapshot,issued_at)
  values(b.id,b.business_id,'LJ-'||to_char(now(),'YYYY')||'-'||lpad(nextval('public.invoice_number_seq')::text,6,'0'),'paid',b.subtotal+b.platform_fee,b.tax_amount,b.total_amount,jsonb_build_object('customer_id',b.customer_id),jsonb_build_object('amount',b.tax_amount),now()) returning id into invoice_id;
  insert into public.invoice_lines(invoice_id,description,quantity,unit_amount,tax_amount,line_total,sort_order) values(invoice_id,'Layanan penyedia',1,b.subtotal,0,b.subtotal,1),(invoice_id,'Biaya platform',1,b.platform_fee,b.tax_amount,b.platform_fee+b.tax_amount,2);
  insert into public.notifications(user_id,event_type,channel,template_version,payload) select owner_user_id,'booking.confirmed','in_app','v1',jsonb_build_object('booking_id',b.id) from public.providers where id=b.provider_id;
  return b.id;
end;
$$;

create or replace function public.transition_booking(p_booking_id uuid,p_to_status text,p_note text,p_idempotency_key text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid()); b public.bookings; actor_is_provider boolean; actor_is_customer boolean;
begin
  if actor_id is null then raise exception 'authentication required' using errcode='28000'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null then raise exception 'booking not found' using errcode='P0002'; end if;
  if exists(select 1 from public.idempotency_keys where principal_id=actor_id and scope='booking.transition' and key=p_idempotency_key) then return b.id; end if;
  actor_is_customer := b.customer_id=actor_id; actor_is_provider := private.is_provider_member(b.provider_id,null);
  if not (
    (actor_is_provider and ((b.status='confirmed' and p_to_status='accepted') or (b.status='accepted' and p_to_status='en_route') or (b.status='en_route' and p_to_status='in_progress') or (b.status='in_progress' and p_to_status='provider_completed')))
    or (actor_is_customer and b.status='provider_completed' and p_to_status='customer_confirmed')
    or (actor_is_customer and b.status='customer_confirmed' and p_to_status='closed')
  ) then raise exception 'invalid booking transition' using errcode='22023'; end if;
  update public.bookings set status=p_to_status,updated_at=now(),version=version+1 where id=b.id;
  update public.jobs set status=p_to_status,updated_at=now(),version=version+1 where id=b.job_id;
  insert into public.job_status_events(booking_id,from_status,to_status,actor_user_id,reason_code,note) values(b.id,b.status,p_to_status,actor_id,'manual_transition',nullif(trim(p_note),''));
  insert into public.idempotency_keys(principal_id,scope,key,request_hash,response_status,resource_id,expires_at) values(actor_id,'booking.transition',p_idempotency_key,pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(concat_ws('|',b.id,b.status,p_to_status)::text,'UTF8')),'hex'),200,b.id,now()+interval '24 hours');
  if p_to_status='customer_confirmed' then update public.payment_holds set status='released',released_at=now(),version=version+1 where booking_id=b.id and status='held'; end if;
  return b.id;
end;
$$;

revoke all on function public.submit_job_request(uuid,text,text,timestamptz,timestamptz,bigint,bigint,text) from public;
revoke all on function public.submit_job_quote(uuid,uuid,bigint,integer,text,timestamptz) from public;
revoke all on function public.accept_quote_and_create_booking(uuid,timestamptz,text) from public;
revoke all on function public.capture_sandbox_payment(uuid) from public;
revoke all on function public.transition_booking(uuid,text,text,text) from public;
grant execute on function public.submit_job_request(uuid,text,text,timestamptz,timestamptz,bigint,bigint,text) to authenticated;
grant execute on function public.submit_job_quote(uuid,uuid,bigint,integer,text,timestamptz) to authenticated;
grant execute on function public.accept_quote_and_create_booking(uuid,timestamptz,text) to authenticated;
grant execute on function public.capture_sandbox_payment(uuid) to authenticated;
grant execute on function public.transition_booking(uuid,text,text,text) to authenticated;

commit;
