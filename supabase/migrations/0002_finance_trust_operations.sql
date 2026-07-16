begin;

create table public.verification_cases (
  id uuid primary key default gen_random_uuid(), subject_user_id uuid references public.profiles(id), provider_id uuid references public.providers(id),
  business_id uuid references public.businesses(id), kind text not null check (kind in ('kyc','kyb','payout')),
  vendor text, vendor_reference text, status text not null default 'pending' check (status in ('pending','processing','manual_review','approved','rejected','expired')),
  risk_score numeric(5,2) check (risk_score between 0 and 100), decision_reason text, reviewed_by uuid references public.profiles(id),
  submitted_at timestamptz not null default now(), decided_at timestamptz,
  check (num_nonnulls(subject_user_id,provider_id,business_id) >= 1)
);

create table public.compliance_documents (
  id uuid primary key default gen_random_uuid(), verification_case_id uuid not null references public.verification_cases(id) on delete cascade,
  file_id uuid not null references public.files(id), document_type text not null, country_code char(2) not null default 'ID',
  extracted_data jsonb, expires_on date, status text not null default 'pending' check (status in ('pending','verified','rejected','expired')),
  created_at timestamptz not null default now()
);

create table public.fraud_signals (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id), booking_id uuid references public.bookings(id),
  signal_type text not null, source text not null, score numeric(6,3) not null, payload jsonb not null default '{}',
  observed_at timestamptz not null default now(), expires_at timestamptz
);

create table public.fraud_cases (
  id uuid primary key default gen_random_uuid(), subject_user_id uuid references public.profiles(id), booking_id uuid references public.bookings(id),
  status text not null default 'open' check (status in ('open','reviewing','cleared','confirmed','appealed','closed')),
  risk_score numeric(5,2) not null check (risk_score between 0 and 100), severity text not null check (severity in ('low','medium','high','critical')),
  assigned_to uuid references public.profiles(id), decision_reason text, created_at timestamptz not null default now(), closed_at timestamptz
);

create table public.blacklist_entries (
  id uuid primary key default gen_random_uuid(), subject_type text not null check (subject_type in ('user','device_hash','phone_hash','email_hash','bank_hash')),
  subject_hash text not null, reason_code text not null, status text not null default 'active' check (status in ('active','expired','revoked')),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), expires_at timestamptz,
  unique(subject_type,subject_hash)
);

create table public.payment_intents (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
  provider text not null, provider_reference text, status text not null default 'created' check (status in ('created','pending','authorized','captured','failed','cancelled','expired','refunded','partially_refunded')),
  amount bigint not null check (amount > 0), currency char(3) not null default 'IDR', checkout_url text,
  idempotency_key text not null, expires_at timestamptz, version integer not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(provider,provider_reference), unique(provider,idempotency_key)
);

create table public.payment_events (
  id bigint generated always as identity primary key, provider text not null, provider_event_id text not null,
  payment_intent_id uuid references public.payment_intents(id), event_type text not null, signature_valid boolean not null,
  payload jsonb not null, received_at timestamptz not null default now(), processed_at timestamptz, processing_error text,
  unique(provider,provider_event_id)
);

create table public.ledger_accounts (
  id uuid primary key default gen_random_uuid(), owner_type text not null check (owner_type in ('platform','customer','provider','psp','tax')),
  owner_id uuid, account_type text not null check (account_type in ('asset','liability','revenue','expense','clearing')),
  currency char(3) not null default 'IDR', name text not null, status text not null default 'active' check (status in ('active','frozen','closed')),
  created_at timestamptz not null default now(), unique(owner_type,owner_id,account_type,currency,name)
);

create table public.ledger_transactions (
  id uuid primary key default gen_random_uuid(), reference_type text not null, reference_id uuid, kind text not null,
  status text not null default 'posted' check (status in ('pending','posted','reversed')),
  reverses_transaction_id uuid references public.ledger_transactions(id), description text, created_by uuid references public.profiles(id),
  posted_at timestamptz not null default now(), created_at timestamptz not null default now()
);

create table public.ledger_entries (
  id bigint generated always as identity primary key, transaction_id uuid not null references public.ledger_transactions(id),
  account_id uuid not null references public.ledger_accounts(id), amount bigint not null check (amount <> 0), currency char(3) not null default 'IDR',
  created_at timestamptz not null default now()
);

create table public.payment_holds (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), payment_intent_id uuid not null references public.payment_intents(id),
  amount bigint not null check (amount > 0), currency char(3) not null default 'IDR',
  status text not null default 'held' check (status in ('held','partially_released','released','partially_refunded','refunded','frozen')),
  held_at timestamptz not null default now(), released_at timestamptz, version integer not null default 1
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), payment_intent_id uuid not null references public.payment_intents(id),
  provider_reference text, amount bigint not null check (amount > 0), currency char(3) not null default 'IDR', reason_code text not null,
  status text not null default 'requested' check (status in ('requested','approved','processing','succeeded','failed','cancelled')),
  requested_by uuid not null references public.profiles(id), approved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(), processed_at timestamptz,
  check (approved_by is null or approved_by <> requested_by)
);

create table public.payouts (
  id uuid primary key default gen_random_uuid(), provider_id uuid not null references public.providers(id), booking_id uuid references public.bookings(id),
  provider_reference text, amount bigint not null check (amount > 0), currency char(3) not null default 'IDR',
  status text not null default 'queued' check (status in ('queued','processing','paid','failed','cancelled','reversed')),
  scheduled_at timestamptz, processed_at timestamptz, created_at timestamptz not null default now()
);

create table public.disputes (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), opened_by uuid not null references public.profiles(id),
  reason_code text not null, description text not null, disputed_amount bigint not null check (disputed_amount >= 0), currency char(3) not null default 'IDR',
  status text not null default 'open' check (status in ('open','awaiting_customer','awaiting_provider','under_review','resolved','appealed','closed')),
  assigned_to uuid references public.profiles(id), resolution text, resolved_refund bigint check (resolved_refund is null or resolved_refund >= 0),
  opened_at timestamptz not null default now(), resolved_at timestamptz, version integer not null default 1
);

create table public.dispute_evidence (
  id uuid primary key default gen_random_uuid(), dispute_id uuid not null references public.disputes(id) on delete cascade,
  submitted_by uuid not null references public.profiles(id), file_id uuid references public.files(id), note text,
  created_at timestamptz not null default now(), check (file_id is not null or note is not null)
);

create table public.invoices (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.bookings(id), business_id uuid references public.businesses(id),
  invoice_number text not null unique, status text not null default 'issued' check (status in ('draft','issued','void','paid')),
  currency char(3) not null default 'IDR', subtotal bigint not null, tax_amount bigint not null default 0, total_amount bigint not null,
  billing_snapshot jsonb not null, tax_snapshot jsonb not null default '{}', issued_at timestamptz, due_at timestamptz, file_id uuid references public.files(id),
  created_at timestamptz not null default now(), check (total_amount = subtotal + tax_amount)
);

create table public.invoice_lines (
  id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null, quantity numeric(12,3) not null check (quantity > 0), unit_amount bigint not null, tax_amount bigint not null default 0,
  line_total bigint not null, sort_order integer not null default 0
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), customer_id uuid not null references public.profiles(id),
  provider_id uuid not null references public.providers(id), rating smallint not null check (rating between 1 and 5), title text, body text,
  status text not null default 'pending' check (status in ('pending','published','flagged','hidden','removed')),
  moderation jsonb not null default '{}', provider_response text, responded_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(booking_id,customer_id)
);

create table public.notification_preferences (
  user_id uuid not null references public.profiles(id) on delete cascade, channel text not null check (channel in ('in_app','email','push','whatsapp','sms')),
  event_type text not null, enabled boolean not null default true, quiet_hours jsonb, primary key(user_id,channel,event_type)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null, channel text not null check (channel in ('in_app','email','push','whatsapp','sms')),
  template_version text not null, payload jsonb not null, status text not null default 'queued' check (status in ('queued','sending','sent','delivered','failed','suppressed')),
  provider_reference text, attempt_count integer not null default 0, scheduled_at timestamptz not null default now(), sent_at timestamptz, read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.ai_runs (
  id uuid primary key default gen_random_uuid(), module text not null, subject_type text not null, subject_id uuid,
  model_provider text not null, model_version text not null, prompt_version text not null, schema_version text not null,
  status text not null check (status in ('queued','running','succeeded','failed','fallback','rejected')),
  input_hash text not null, latency_ms integer, input_tokens integer, output_tokens integer, estimated_cost numeric(14,6),
  trace_id text, created_at timestamptz not null default now(), completed_at timestamptz
);

create table public.ai_predictions (
  id uuid primary key default gen_random_uuid(), ai_run_id uuid not null references public.ai_runs(id), prediction_type text not null,
  output jsonb not null, confidence numeric(6,5) check (confidence between 0 and 1), explanation jsonb not null default '{}',
  accepted_by uuid references public.profiles(id), feedback jsonb, created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key, occurred_at timestamptz not null default now(), actor_user_id uuid references public.profiles(id),
  actor_type text not null check (actor_type in ('user','staff','system','vendor')), action text not null, resource_type text not null, resource_id text,
  business_id uuid references public.businesses(id), reason text, before_hash text, after_hash text, ip_hash text, user_agent_hash text, correlation_id text not null,
  metadata jsonb not null default '{}'
);

create table public.activity_logs (
  id bigint generated always as identity primary key, user_id uuid references public.profiles(id), event_name text not null,
  entity_type text, entity_id uuid, occurred_at timestamptz not null default now(), properties jsonb not null default '{}'
);

create table public.outbox_events (
  id uuid primary key default gen_random_uuid(), aggregate_type text not null, aggregate_id uuid not null, event_type text not null,
  payload jsonb not null, correlation_id text not null, available_at timestamptz not null default now(), attempt_count integer not null default 0,
  locked_at timestamptz, locked_by text, published_at timestamptz, last_error text, created_at timestamptz not null default now()
);

create table public.idempotency_keys (
  principal_id uuid not null, scope text not null, key text not null, request_hash text not null,
  response_status integer, response_body jsonb, resource_id uuid, expires_at timestamptz not null, created_at timestamptz not null default now(),
  primary key(principal_id,scope,key)
);

create table public.system_settings (
  key text not null, version integer not null, value jsonb not null, effective_from timestamptz not null,
  effective_to timestamptz, status text not null default 'active' check (status in ('draft','active','retired')),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), primary key(key,version)
);

create table public.business_cost_centers (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  code citext not null, name text not null, budget_amount bigint check (budget_amount is null or budget_amount >= 0),
  currency char(3) not null default 'IDR', status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(), unique(business_id,code)
);

create table public.business_approval_rules (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null, priority integer not null default 100, conditions jsonb not null, required_approvals smallint not null default 1 check (required_approvals > 0),
  approver_roles text[] not null default array['approver'], effective_from timestamptz not null, effective_to timestamptz,
  version integer not null default 1, status text not null default 'draft' check (status in ('draft','active','retired')),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now()
);

create table public.approval_requests (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id), job_id uuid references public.jobs(id),
  requested_by uuid not null references public.profiles(id), rule_id uuid references public.business_approval_rules(id),
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled','expired')),
  amount bigint check (amount is null or amount >= 0), currency char(3) not null default 'IDR', policy_snapshot jsonb not null,
  decided_by uuid references public.profiles(id), decision_reason text, requested_at timestamptz not null default now(), decided_at timestamptz
);

create table public.pricing_rules (
  id uuid primary key default gen_random_uuid(), service_id uuid references public.services(id), region_code text,
  booking_type text check (booking_type in ('instant','scheduled','emergency')), rule jsonb not null,
  effective_from timestamptz not null, effective_to timestamptz, version integer not null, status text not null default 'draft' check (status in ('draft','active','retired')),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(),
  unique(service_id,region_code,booking_type,version)
);

create table public.commission_rules (
  id uuid primary key default gen_random_uuid(), service_id uuid references public.services(id), provider_id uuid references public.providers(id),
  fee_type text not null check (fee_type in ('fixed','percentage','tiered')), rule jsonb not null,
  effective_from timestamptz not null, effective_to timestamptz, version integer not null, status text not null default 'draft' check (status in ('draft','active','retired')),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(),
  unique(service_id,provider_id,version)
);

create table public.contracts (
  id uuid primary key default gen_random_uuid(), business_id uuid references public.businesses(id), provider_id uuid references public.providers(id),
  contract_number text not null unique, kind text not null, status text not null default 'draft' check (status in ('draft','pending_signature','active','expired','terminated')),
  starts_on date, ends_on date, terms_snapshot jsonb not null, file_id uuid references public.files(id),
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (business_id is not null or provider_id is not null), check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(), requester_id uuid not null references public.profiles(id), booking_id uuid references public.bookings(id),
  category text not null, subject text not null, description text not null, priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','waiting_user','waiting_internal','resolved','closed')),
  assigned_to uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), resolved_at timestamptz
);

create table public.cms_pages (
  id uuid primary key default gen_random_uuid(), slug citext not null, locale text not null default 'id-ID', title text not null,
  content jsonb not null, version integer not null, status text not null default 'draft' check (status in ('draft','published','archived')),
  published_at timestamptz, created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(),
  unique(slug,locale,version)
);

create table public.banners (
  id uuid primary key default gen_random_uuid(), placement text not null, locale text not null default 'id-ID', title text,
  image_file_id uuid not null references public.files(id), target_url text, starts_at timestamptz, ends_at timestamptz,
  status text not null default 'draft' check (status in ('draft','active','paused','archived')), sort_order integer not null default 0,
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index addresses_user_idx on public.addresses(user_id);
create index business_members_user_idx on public.business_members(user_id) where status = 'active';
create index provider_members_user_idx on public.provider_members(user_id) where status = 'active';
create index provider_services_provider_idx on public.provider_services(provider_id,status);
create index provider_services_service_idx on public.provider_services(service_id,status);
create index provider_area_gist on public.provider_service_areas using gist(area);
create index jobs_customer_idx on public.jobs(customer_id,created_at desc);
create index jobs_business_idx on public.jobs(business_id,created_at desc) where business_id is not null;
create index jobs_open_idx on public.jobs(status,requested_start) where status not in ('closed','cancelled');
create index job_matches_job_rank_idx on public.job_matches(job_id,rank);
create index bookings_provider_idx on public.bookings(provider_id,scheduled_start);
create index status_events_booking_idx on public.job_status_events(booking_id,created_at);
create index tracking_booking_time_idx on public.tracking_points(booking_id,captured_at desc);
create index messages_conversation_idx on public.messages(conversation_id,created_at,id);
create index payment_intents_booking_idx on public.payment_intents(booking_id,created_at desc);
create index ledger_entries_tx_idx on public.ledger_entries(transaction_id);
create index ledger_entries_account_idx on public.ledger_entries(account_id,created_at);
create index disputes_booking_idx on public.disputes(booking_id,status);
create index notifications_queue_idx on public.notifications(status,scheduled_at) where status in ('queued','failed');
create index outbox_pending_idx on public.outbox_events(available_at) where published_at is null;
create index audit_resource_idx on public.audit_logs(resource_type,resource_id,occurred_at desc);
create index approval_requests_business_idx on public.approval_requests(business_id,status,requested_at);
create index support_tickets_queue_idx on public.support_tickets(status,priority,created_at);
create index contracts_business_idx on public.contracts(business_id,status) where business_id is not null;

commit;
