begin;

create table public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  request_type text not null check (request_type in ('access','export','correction','deletion','consent_withdrawal')),
  description text not null,
  status text not null default 'submitted' check (status in ('submitted','verifying','processing','completed','rejected','cancelled')),
  decision_reason text,
  handled_by uuid references public.profiles(id),
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);
alter table public.privacy_requests enable row level security;
grant select on public.privacy_requests to authenticated;
grant select on public.business_approval_rules, public.approval_requests to authenticated;

create policy privacy_own_read on public.privacy_requests for select to authenticated using (user_id=(select auth.uid()));
create policy privacy_staff_read on public.privacy_requests for select to authenticated using (
  private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);
create policy approval_rules_member_read on public.business_approval_rules for select to authenticated using (private.is_business_member(business_id,null));
create policy approval_requests_member_read on public.approval_requests for select to authenticated using (private.is_business_member(business_id,null));
create policy disputes_staff_read on public.disputes for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('finance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);
create policy refunds_staff_read on public.refunds for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('finance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);

revoke insert,update on public.disputes,public.dispute_evidence,public.reviews from authenticated;

create or replace function public.create_business(p_legal_name text,p_display_name text,p_billing_email text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());new_id uuid;
begin
 if actor_id is null then raise exception 'authentication required' using errcode='28000';end if;
 if length(trim(p_legal_name))<3 or length(trim(p_display_name))<3 then raise exception 'invalid business name' using errcode='22023';end if;
 insert into public.businesses(legal_name,display_name,billing_email,created_by) values(trim(p_legal_name),trim(p_display_name),nullif(trim(p_billing_email),''),actor_id) returning id into new_id;
 insert into public.business_members(business_id,user_id,role,status) values(new_id,actor_id,'owner','active');
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,correlation_id) values(actor_id,'user','business.created','business',new_id::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
 return new_id;
end;$$;

create or replace function public.add_business_member(p_business_id uuid,p_email text,p_role text,p_spend_limit bigint,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());target_user uuid;
begin
 if not private.is_business_member(p_business_id,array['owner','admin']) then raise exception 'business admin access required' using errcode='42501';end if;
 if p_role not in ('admin','requester','approver','viewer') or p_spend_limit<0 then raise exception 'invalid membership' using errcode='22023';end if;
 select id into target_user from public.profiles where lower(email::text)=lower(trim(p_email));if target_user is null then raise exception 'account not found' using errcode='P0002';end if;
 insert into public.business_members(business_id,user_id,role,status,spend_limit) values(p_business_id,target_user,p_role,'active',p_spend_limit)
 on conflict(business_id,user_id) do update set role=excluded.role,status='active',spend_limit=excluded.spend_limit;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,business_id,correlation_id,metadata) values(actor_id,'user','business.member_upserted','business_member',target_user::text,p_business_id,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text),jsonb_build_object('role',p_role));
end;$$;

create or replace function public.create_business_approval_rule(p_business_id uuid,p_name text,p_threshold bigint,p_required_approvals smallint,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());new_id uuid;
begin
 if not private.is_business_member(p_business_id,array['owner','admin']) then raise exception 'business admin access required' using errcode='42501';end if;
 if p_threshold<0 or p_required_approvals<>1 then raise exception 'pilot supports one independent approval' using errcode='22023';end if;
 insert into public.business_approval_rules(business_id,name,conditions,required_approvals,approver_roles,effective_from,status,created_by)
 values(p_business_id,trim(p_name),jsonb_build_object('amount_gte',p_threshold),p_required_approvals,array['owner','admin','approver'],now(),'active',actor_id) returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,business_id,correlation_id) values(actor_id,'user','business.approval_rule_created','approval_rule',new_id::text,p_business_id,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;
end;$$;

create or replace function public.request_business_job_approval(p_business_id uuid,p_job_id uuid,p_amount bigint,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());selected_rule public.business_approval_rules;new_id uuid;
begin
 if not private.is_business_member(p_business_id,array['owner','admin','requester']) then raise exception 'requester access required' using errcode='42501';end if;
 if not exists(select 1 from public.jobs where id=p_job_id and customer_id=actor_id and status in('requested','matched')) then raise exception 'eligible job not found' using errcode='P0002';end if;
 select * into selected_rule from public.business_approval_rules r where r.business_id=p_business_id and r.status='active' and r.effective_from<=now() and (r.effective_to is null or r.effective_to>now()) and p_amount>=coalesce((r.conditions->>'amount_gte')::bigint,0) order by priority,id limit 1;
 if selected_rule.id is null then raise exception 'no applicable approval rule' using errcode='P0002';end if;
 update public.jobs set business_id=p_business_id,updated_at=now(),version=version+1 where id=p_job_id;
 insert into public.approval_requests(business_id,job_id,requested_by,rule_id,status,amount,policy_snapshot)
 values(p_business_id,p_job_id,actor_id,selected_rule.id,'pending',p_amount,jsonb_build_object('rule_id',selected_rule.id,'rule_version',selected_rule.version,'conditions',selected_rule.conditions,'required_approvals',selected_rule.required_approvals)) returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,business_id,correlation_id) values(actor_id,'user','business.approval_requested','approval_request',new_id::text,p_business_id,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;
end;$$;

create or replace function public.decide_business_approval(p_request_id uuid,p_decision text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());req public.approval_requests;
begin
 select * into req from public.approval_requests where id=p_request_id and status='pending' for update;if req.id is null then raise exception 'pending request not found' using errcode='P0002';end if;
 if not private.is_business_member(req.business_id,array['owner','admin','approver']) or actor_id=req.requested_by then raise exception 'independent approver required' using errcode='42501';end if;
 if p_decision not in('approved','rejected') or length(trim(p_reason))<8 then raise exception 'reasoned decision required' using errcode='22023';end if;
 update public.approval_requests set status=p_decision,decided_by=actor_id,decision_reason=trim(p_reason),decided_at=now() where id=req.id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,business_id,reason,correlation_id) values(actor_id,'user','business.approval_'||p_decision,'approval_request',req.id::text,req.business_id,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function private.enforce_booking_business_approval()
returns trigger language plpgsql security definer set search_path='' as $$
declare business_target uuid;threshold bigint;
begin
 select business_id into business_target from public.jobs where id=new.job_id;if business_target is null then return new;end if;
 select min((conditions->>'amount_gte')::bigint) into threshold from public.business_approval_rules where business_id=business_target and status='active' and effective_from<=now() and (effective_to is null or effective_to>now());
 if threshold is not null and new.total_amount>=threshold and not exists(select 1 from public.approval_requests where job_id=new.job_id and status='approved' and amount>=new.total_amount) then raise exception 'business approval required' using errcode='42501';end if;return new;
end;$$;
create trigger booking_business_approval before insert on public.bookings for each row execute function private.enforce_booking_business_approval();

create or replace function public.open_booking_dispute(p_booking_id uuid,p_reason_code text,p_description text,p_amount bigint,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());b public.bookings;new_id uuid;
begin
 select * into b from public.bookings where id=p_booking_id for update;if b.id is null or not private.is_booking_participant(b.id) then raise exception 'booking access denied' using errcode='42501';end if;
 if b.status not in('in_progress','provider_completed','customer_confirmed') or p_amount<0 or p_amount>b.total_amount or length(trim(p_description))<20 then raise exception 'dispute not eligible' using errcode='22023';end if;
 insert into public.disputes(booking_id,opened_by,reason_code,description,disputed_amount,status) values(b.id,actor_id,p_reason_code,trim(p_description),p_amount,'open') returning id into new_id;
 update public.bookings set status='disputed',updated_at=now(),version=version+1 where id=b.id;update public.jobs set status='disputed',updated_at=now(),version=version+1 where id=b.job_id;update public.payment_holds set status='frozen',version=version+1 where booking_id=b.id and status in('held','released');
 insert into public.job_status_events(booking_id,from_status,to_status,actor_user_id,reason_code,note) values(b.id,b.status,'disputed',actor_id,p_reason_code,trim(p_description));
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'user','dispute.opened','dispute',new_id::text,p_reason_code,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;
end;$$;

create or replace function public.add_dispute_evidence_note(p_dispute_id uuid,p_note text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());d public.disputes;new_id uuid;
begin
 select * into d from public.disputes where id=p_dispute_id and status not in('resolved','closed') for update;
 if d.id is null or not private.is_booking_participant(d.booking_id) then raise exception 'active dispute access denied' using errcode='42501';end if;
 if length(trim(p_note))<10 then raise exception 'evidence note too short' using errcode='22023';end if;
 insert into public.dispute_evidence(dispute_id,submitted_by,note) values(d.id,actor_id,trim(p_note)) returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,correlation_id,metadata) values(actor_id,'user','dispute.evidence_added','dispute',d.id::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text),jsonb_build_object('evidence_id',new_id));
 return new_id;
end;$$;

create or replace function public.recommend_dispute_resolution(p_dispute_id uuid,p_resolution text,p_refund_amount bigint,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());d public.disputes;intent_id uuid;new_refund uuid;
begin
 if not(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'support AAL2 required' using errcode='42501';end if;
 select * into d from public.disputes where id=p_dispute_id and status in('open','under_review','awaiting_customer','awaiting_provider') for update;if d.id is null then raise exception 'active dispute not found' using errcode='P0002';end if;
 if length(trim(p_resolution))<20 or p_refund_amount<0 or p_refund_amount>d.disputed_amount then raise exception 'invalid resolution' using errcode='22023';end if;
 update public.disputes set status='under_review',assigned_to=actor_id,resolution=trim(p_resolution),resolved_refund=p_refund_amount where id=d.id;
 if p_refund_amount>0 then select id into intent_id from public.payment_intents where booking_id=d.booking_id and status in('captured','partially_refunded') order by created_at desc limit 1;insert into public.refunds(booking_id,payment_intent_id,amount,reason_code,status,requested_by) values(d.booking_id,intent_id,p_refund_amount,'dispute_resolution','requested',actor_id) returning id into new_refund;end if;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id,metadata) values(actor_id,'staff','dispute.resolution_recommended','dispute',d.id::text,trim(p_resolution),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text),jsonb_build_object('refund_amount',p_refund_amount));return new_refund;
end;$$;

create or replace function public.approve_sandbox_refund(p_refund_id uuid,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());r public.refunds;b public.bookings;d public.disputes;tx uuid;psp uuid;provider_payable uuid;platform_revenue uuid;provider_part bigint;fee_part bigint;
begin
 if not(private.has_platform_role('finance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'finance AAL2 required' using errcode='42501';end if;if length(trim(p_reason))<8 then raise exception 'approval reason required' using errcode='22023';end if;
 select * into r from public.refunds where id=p_refund_id and status='requested' for update;if r.id is null or r.requested_by=actor_id then raise exception 'independent refund approver required' using errcode='42501';end if;
 if coalesce(current_setting('app.environment',true),'production')='production' then raise exception 'sandbox refund disabled in production' using errcode='42501';end if;
 select * into b from public.bookings where id=r.booking_id;select * into d from public.disputes where booking_id=b.id and status='under_review' order by opened_at desc limit 1;
 provider_part:=least(r.amount,b.subtotal);fee_part:=r.amount-provider_part;
 select id into psp from public.ledger_accounts where owner_type='psp' and name='Sandbox PSP cash';select id into provider_payable from public.ledger_accounts where owner_type='provider' and owner_id=b.provider_id and name='Provider payable';select id into platform_revenue from public.ledger_accounts where owner_type='platform' and name='Platform fee';
 insert into public.ledger_transactions(reference_type,reference_id,kind,description,created_by) values('refund',r.id,'refund_succeeded','Sandbox dispute refund',actor_id) returning id into tx;
 insert into public.ledger_entries(transaction_id,account_id,amount) values(tx,psp,-r.amount),(tx,provider_payable,provider_part);if fee_part>0 then insert into public.ledger_entries(transaction_id,account_id,amount) values(tx,platform_revenue,fee_part);end if;
 update public.refunds set status='succeeded',approved_by=actor_id,processed_at=now() where id=r.id;update public.payment_intents set status=case when r.amount=b.total_amount then 'refunded' else 'partially_refunded' end,updated_at=now(),version=version+1 where id=r.payment_intent_id;update public.payment_holds set status=case when r.amount=b.total_amount then 'refunded' else 'partially_refunded' end,version=version+1 where booking_id=b.id;update public.disputes set status='resolved',resolved_at=now() where id=d.id;update public.bookings set status='resolved',updated_at=now(),version=version+1 where id=b.id;update public.jobs set status='resolved',updated_at=now(),version=version+1 where id=b.job_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','refund.approved','refund',r.id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function public.submit_verified_review(p_booking_id uuid,p_rating smallint,p_title text,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());b public.bookings;new_id uuid;
begin select * into b from public.bookings where id=p_booking_id and customer_id=actor_id and status in('customer_confirmed','closed','resolved');if b.id is null or p_rating not between 1 and 5 then raise exception 'review not eligible' using errcode='22023';end if;
 insert into public.reviews(booking_id,customer_id,provider_id,rating,title,body,status) values(b.id,actor_id,b.provider_id,p_rating,nullif(trim(p_title),''),nullif(trim(p_body),''),'published') returning id into new_id;
 update public.providers set rating_avg=(select avg(rating)::numeric(3,2) from public.reviews where provider_id=b.provider_id and status='published'),rating_count=(select count(*) from public.reviews where provider_id=b.provider_id and status='published'),updated_at=now() where id=b.provider_id;return new_id;end;$$;

create or replace function public.submit_privacy_request(p_type text,p_description text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());new_id uuid;begin if actor_id is null or p_type not in('access','export','correction','deletion','consent_withdrawal') or length(trim(p_description))<10 then raise exception 'invalid privacy request' using errcode='22023';end if;insert into public.privacy_requests(user_id,request_type,description) values(actor_id,p_type,trim(p_description)) returning id into new_id;insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,correlation_id) values(actor_id,'user','privacy.request_submitted','privacy_request',new_id::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;end;$$;

create or replace function public.complete_privacy_request(p_request_id uuid,p_status text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());begin if not(private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'compliance AAL2 required' using errcode='42501';end if;if p_status not in('completed','rejected') or length(trim(p_reason))<10 then raise exception 'reasoned outcome required' using errcode='22023';end if;update public.privacy_requests set status=p_status,decision_reason=trim(p_reason),handled_by=actor_id,completed_at=now() where id=p_request_id and status not in('completed','rejected','cancelled');if not found then raise exception 'active request not found' using errcode='P0002';end if;insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','privacy.request_'||p_status,'privacy_request',p_request_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));end;$$;

revoke all on function public.create_business(text,text,text,text),public.add_business_member(uuid,text,text,bigint,text),public.create_business_approval_rule(uuid,text,bigint,smallint,text),public.request_business_job_approval(uuid,uuid,bigint,text),public.decide_business_approval(uuid,text,text,text),public.open_booking_dispute(uuid,text,text,bigint,text),public.add_dispute_evidence_note(uuid,text,text),public.recommend_dispute_resolution(uuid,text,bigint,text),public.approve_sandbox_refund(uuid,text,text),public.submit_verified_review(uuid,smallint,text,text),public.submit_privacy_request(text,text,text),public.complete_privacy_request(uuid,text,text,text) from public;
grant execute on function public.create_business(text,text,text,text),public.add_business_member(uuid,text,text,bigint,text),public.create_business_approval_rule(uuid,text,bigint,smallint,text),public.request_business_job_approval(uuid,uuid,bigint,text),public.decide_business_approval(uuid,text,text,text),public.open_booking_dispute(uuid,text,text,bigint,text),public.add_dispute_evidence_note(uuid,text,text),public.recommend_dispute_resolution(uuid,text,bigint,text),public.approve_sandbox_refund(uuid,text,text),public.submit_verified_review(uuid,smallint,text,text),public.submit_privacy_request(text,text,text),public.complete_privacy_request(uuid,text,text,text) to authenticated;

commit;
