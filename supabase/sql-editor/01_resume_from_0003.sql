-- Lumina Jasa - recovery after the spatial_ref_sys failure in 0003_rls.sql
-- Use this only when 0001 and 0002 succeeded and 0003 failed with SQLSTATE 42501.
-- It installs the corrected 0003 migration and continues through 0010.

-- ============================================================================
-- 0003_rls.sql
-- ============================================================================
begin;

create or replace function private.has_platform_role(required_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = (select auth.uid()) and r.role = required_role and r.revoked_at is null
  );
$$;

create or replace function private.is_business_member(target_business_id uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.business_members m
    where m.business_id = target_business_id and m.user_id = (select auth.uid()) and m.status = 'active'
      and (allowed_roles is null or m.role = any(allowed_roles))
  );
$$;

create or replace function private.is_provider_member(target_provider_id uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.provider_members m
    where m.provider_id = target_provider_id and m.user_id = (select auth.uid()) and m.status = 'active'
      and (allowed_roles is null or m.role = any(allowed_roles))
  );
$$;

create or replace function private.is_booking_participant(target_booking_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.bookings b
    where b.id = target_booking_id and (
      b.customer_id = (select auth.uid()) or b.assigned_user_id = (select auth.uid())
      or private.is_business_member(b.business_id, null)
      or private.is_provider_member(b.provider_id, null)
    )
  );
$$;

create or replace function private.can_access_file(target_file_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.message_attachments a
    join public.messages m on m.id = a.message_id
    join public.conversation_participants p on p.conversation_id = m.conversation_id
    where a.file_id = target_file_id and p.user_id = (select auth.uid()) and p.left_at is null
  ) or exists (
    select 1 from public.job_media jm join public.jobs j on j.id = jm.job_id
    left join public.bookings b on b.job_id = j.id
    where jm.file_id = target_file_id and (
      j.customer_id = (select auth.uid()) or private.is_business_member(j.business_id,null)
      or (b.id is not null and private.is_provider_member(b.provider_id,null))
    )
  ) or exists (
    select 1 from public.dispute_evidence e join public.disputes d on d.id = e.dispute_id
    where e.file_id = target_file_id and private.is_booking_participant(d.booking_id)
  ) or exists (
    select 1 from public.invoices i where i.file_id = target_file_id and private.is_booking_participant(i.booking_id)
  );
$$;

revoke all on function private.has_platform_role(text) from public;
revoke all on function private.is_business_member(uuid,text[]) from public;
revoke all on function private.is_provider_member(uuid,text[]) from public;
revoke all on function private.is_booking_participant(uuid) from public;
revoke all on function private.can_access_file(uuid) from public;
grant execute on function private.has_platform_role(text), private.is_business_member(uuid,text[]),
  private.is_provider_member(uuid,text[]), private.is_booking_participant(uuid), private.can_access_file(uuid) to authenticated;

do $$
declare t record;
begin
  for t in
    select tablename from pg_tables
    where schemaname = 'public' and tableowner = current_user
  loop
    execute format('alter table public.%I enable row level security', t.tablename);
    execute format('revoke all on table public.%I from anon, authenticated', t.tablename);
  end loop;
end $$;

grant select on public.categories, public.services, public.providers, public.provider_services, public.provider_portfolios, public.reviews to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select on public.user_roles to authenticated;
grant select, insert, update, delete on public.addresses to authenticated;
grant select on public.businesses, public.business_members, public.provider_members to authenticated;
grant select, insert, update on public.jobs, public.bookings to authenticated;
grant select on public.job_matches, public.job_status_events, public.tracking_points to authenticated;
grant select on public.conversations, public.conversation_participants to authenticated;
grant select, insert, update on public.messages, public.message_receipts to authenticated;
grant select, insert on public.message_attachments to authenticated;
grant select, insert, update on public.files to authenticated;
grant select on public.payment_intents, public.payment_holds, public.refunds, public.payouts, public.invoices, public.invoice_lines to authenticated;
grant select, insert, update on public.disputes, public.dispute_evidence to authenticated;
grant select, insert, update on public.reviews to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;
grant select, update on public.notifications to authenticated;
grant select on public.ai_predictions to authenticated;

create policy profiles_own_select on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_own_update on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy roles_own_read on public.user_roles for select to authenticated using (user_id = (select auth.uid()));

create policy addresses_own_all on public.addresses for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy businesses_member_read on public.businesses for select to authenticated
  using (private.is_business_member(id,null));
create policy business_members_member_read on public.business_members for select to authenticated
  using (private.is_business_member(business_id,null));

create policy providers_public_read on public.providers for select to anon, authenticated using (status = 'active' and verification_status = 'verified');
create policy provider_members_member_read on public.provider_members for select to authenticated
  using (private.is_provider_member(provider_id,null));
create policy categories_public_read on public.categories for select to anon, authenticated using (status = 'active');
create policy services_public_read on public.services for select to anon, authenticated using (status = 'active');
create policy provider_services_public_read on public.provider_services for select to anon, authenticated using (
  status = 'active' and exists (select 1 from public.providers p where p.id = provider_services.provider_id and p.status = 'active' and p.verification_status = 'verified')
);
create policy portfolios_public_read on public.provider_portfolios for select to anon, authenticated using (
  status = 'approved' and exists (select 1 from public.providers p where p.id = provider_portfolios.provider_id and p.status = 'active' and p.verification_status = 'verified')
);

create policy jobs_participant_read on public.jobs for select to authenticated using (
  customer_id = (select auth.uid()) or private.is_business_member(business_id,null)
  or exists (select 1 from public.bookings b where b.job_id = jobs.id and private.is_provider_member(b.provider_id,null))
);
create policy jobs_customer_insert on public.jobs for insert to authenticated with check (
  customer_id = (select auth.uid()) and (business_id is null or private.is_business_member(business_id,array['owner','admin','requester']))
);
create policy jobs_customer_update on public.jobs for update to authenticated
  using (customer_id = (select auth.uid()) and status in ('draft','requested'))
  with check (customer_id = (select auth.uid()));

create policy bookings_participant_read on public.bookings for select to authenticated using (private.is_booking_participant(id));
create policy job_matches_customer_read on public.job_matches for select to authenticated
  using (exists (select 1 from public.jobs j where j.id = job_matches.job_id and (j.customer_id = (select auth.uid()) or private.is_business_member(j.business_id,null))));
create policy status_events_participant_read on public.job_status_events for select to authenticated using (private.is_booking_participant(booking_id));
create policy tracking_participant_read on public.tracking_points for select to authenticated using (private.is_booking_participant(booking_id));

create policy conversations_participant_read on public.conversations for select to authenticated using (
  exists (select 1 from public.conversation_participants p where p.conversation_id = conversations.id and p.user_id = (select auth.uid()) and p.left_at is null)
);
create policy participants_participant_read on public.conversation_participants for select to authenticated using (
  exists (select 1 from public.conversation_participants p where p.conversation_id = conversation_participants.conversation_id and p.user_id = (select auth.uid()) and p.left_at is null)
);
create policy messages_participant_read on public.messages for select to authenticated using (
  exists (select 1 from public.conversation_participants p where p.conversation_id = messages.conversation_id and p.user_id = (select auth.uid()) and p.left_at is null)
);
create policy messages_participant_insert on public.messages for insert to authenticated with check (
  sender_user_id = (select auth.uid()) and exists (
    select 1 from public.conversation_participants p where p.conversation_id = messages.conversation_id and p.user_id = (select auth.uid()) and p.left_at is null
  )
);
create policy receipts_own on public.message_receipts for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy attachments_participant_read on public.message_attachments for select to authenticated using (
  exists (select 1 from public.messages m where m.id = message_attachments.message_id)
);
create policy attachments_sender_insert on public.message_attachments for insert to authenticated with check (
  exists (select 1 from public.messages m where m.id = message_attachments.message_id and m.sender_user_id = (select auth.uid()))
);

create policy files_owner_read on public.files for select to authenticated using (
  owner_user_id = (select auth.uid()) or private.is_business_member(business_id,null) or private.can_access_file(id)
);
create policy files_owner_insert on public.files for insert to authenticated with check (
  owner_user_id = (select auth.uid()) and (business_id is null or private.is_business_member(business_id,null))
);
create policy files_owner_update on public.files for update to authenticated using (owner_user_id = (select auth.uid()));

create policy payment_intents_participant_read on public.payment_intents for select to authenticated using (private.is_booking_participant(booking_id));
create policy holds_participant_read on public.payment_holds for select to authenticated using (private.is_booking_participant(booking_id));
create policy refunds_participant_read on public.refunds for select to authenticated using (private.is_booking_participant(booking_id));
create policy payouts_provider_read on public.payouts for select to authenticated using (private.is_provider_member(provider_id,null));
create policy invoices_participant_read on public.invoices for select to authenticated using (private.is_booking_participant(booking_id));
create policy invoice_lines_participant_read on public.invoice_lines for select to authenticated using (
  exists (select 1 from public.invoices i where i.id = invoice_lines.invoice_id and private.is_booking_participant(i.booking_id))
);

create policy disputes_participant_read on public.disputes for select to authenticated using (private.is_booking_participant(booking_id));
create policy disputes_participant_insert on public.disputes for insert to authenticated with check (opened_by = (select auth.uid()) and private.is_booking_participant(booking_id));
create policy evidence_participant_read on public.dispute_evidence for select to authenticated using (
  exists (select 1 from public.disputes d where d.id = dispute_evidence.dispute_id and private.is_booking_participant(d.booking_id))
);
create policy evidence_participant_insert on public.dispute_evidence for insert to authenticated with check (
  submitted_by = (select auth.uid()) and exists (select 1 from public.disputes d where d.id = dispute_evidence.dispute_id and private.is_booking_participant(d.booking_id))
);

create policy reviews_public_read on public.reviews for select to anon, authenticated using (status = 'published');
create policy reviews_customer_insert on public.reviews for insert to authenticated with check (
  customer_id = (select auth.uid()) and exists (
    select 1 from public.bookings b where b.id = reviews.booking_id and b.customer_id = (select auth.uid())
      and b.provider_id = reviews.provider_id and b.status in ('customer_confirmed','closed')
  )
);
create policy preferences_own on public.notification_preferences for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_own_read on public.notifications for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_own_update on public.notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy ai_predictions_subject_read on public.ai_predictions for select to authenticated using (accepted_by = (select auth.uid()));

-- No client policies are intentionally defined for ledger, payment events, audit,
-- system settings, verification and fraud internals. Use narrowly scoped audited RPCs.

commit;

-- ============================================================================
-- 0004_supply_catalog.sql
-- ============================================================================
begin;

alter table public.providers
  add column service_area_labels text[] not null default '{}';

grant select on public.provider_availability, public.provider_service_areas to anon, authenticated;
grant insert, update, delete on public.provider_services, public.provider_availability, public.provider_service_areas to authenticated;
grant select on public.verification_cases, public.compliance_documents to authenticated;
grant update(display_name, bio, base_location, service_radius_km, service_area_labels) on public.providers to authenticated;

create policy providers_member_read on public.providers for select to authenticated using (
  owner_user_id = (select auth.uid()) or private.is_provider_member(id, null)
);
create policy providers_staff_read on public.providers for select to authenticated using (
  private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')
);
create policy providers_member_update on public.providers for update to authenticated
  using (private.is_provider_member(id, array['owner','manager']))
  with check (private.is_provider_member(id, array['owner','manager']));

create policy provider_services_member_all on public.provider_services for all to authenticated
  using (private.is_provider_member(provider_id, array['owner','manager']))
  with check (private.is_provider_member(provider_id, array['owner','manager']));

create policy availability_public_read on public.provider_availability for select to anon, authenticated using (
  exists (select 1 from public.providers p where p.id = provider_availability.provider_id and p.status = 'active' and p.verification_status = 'verified')
);
create policy availability_member_all on public.provider_availability for all to authenticated
  using (private.is_provider_member(provider_id, array['owner','manager']))
  with check (private.is_provider_member(provider_id, array['owner','manager']));

create policy service_areas_public_read on public.provider_service_areas for select to anon, authenticated using (
  exists (select 1 from public.providers p where p.id = provider_service_areas.provider_id and p.status = 'active' and p.verification_status = 'verified')
);
create policy service_areas_member_all on public.provider_service_areas for all to authenticated
  using (private.is_provider_member(provider_id, array['owner','manager']))
  with check (private.is_provider_member(provider_id, array['owner','manager']));

create policy verification_subject_read on public.verification_cases for select to authenticated using (
  subject_user_id = (select auth.uid())
  or (provider_id is not null and private.is_provider_member(provider_id, null))
  or (business_id is not null and private.is_business_member(business_id, null))
  or private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')
);

create policy compliance_documents_subject_read on public.compliance_documents for select to authenticated using (
  exists (
    select 1 from public.verification_cases v
    where v.id = compliance_documents.verification_case_id and (
      v.subject_user_id = (select auth.uid())
      or (v.provider_id is not null and private.is_provider_member(v.provider_id, null))
      or private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')
    )
  )
);
create policy files_staff_read on public.files for select to authenticated using (
  private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')
);

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('compliance-documents', 'compliance-documents', false, 8388608, array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy compliance_objects_owner_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'compliance-documents' and (storage.foldername(name))[1] = (select auth.uid())::text
);
create policy compliance_objects_owner_read on storage.objects for select to authenticated using (
  bucket_id = 'compliance-documents' and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')
  )
);
create policy compliance_objects_owner_delete on storage.objects for delete to authenticated using (
  bucket_id = 'compliance-documents' and (storage.foldername(name))[1] = (select auth.uid())::text
);

create or replace function public.submit_provider_onboarding(
  provider_display_name text,
  provider_slug text,
  provider_bio text,
  verification_kind text,
  catalog_service_id uuid,
  listing_title text,
  listing_pricing_type text,
  listing_base_price bigint,
  coverage_labels text[],
  coverage_radius_km numeric,
  available_weekdays smallint[],
  available_starts_at time,
  available_ends_at time,
  verification_document_path text,
  verification_document_name text,
  verification_document_mime text,
  verification_document_size bigint,
  verification_document_type text,
  request_correlation_id text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid());
  new_provider_id uuid;
  new_verification_case_id uuid;
  new_file_id uuid;
  weekday_value smallint;
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if verification_kind not in ('kyc','kyb') then raise exception 'invalid verification kind' using errcode = '22023'; end if;
  if listing_pricing_type not in ('fixed','hourly','from','quote') then raise exception 'invalid pricing type' using errcode = '22023'; end if;
  if trim(provider_display_name) = '' or trim(provider_slug) = '' or trim(listing_title) = '' then
    raise exception 'required provider fields are empty' using errcode = '22023';
  end if;
  if available_starts_at >= available_ends_at then raise exception 'invalid availability window' using errcode = '22023'; end if;
  if verification_document_mime not in ('application/pdf','image/jpeg','image/png') or verification_document_size <= 0 or verification_document_size > 8388608 then
    raise exception 'invalid verification document' using errcode = '22023';
  end if;
  if verification_document_type not in ('identity','business_registration') or verification_document_path not like actor_id::text || '/%' then
    raise exception 'invalid verification document ownership' using errcode = '22023';
  end if;

  insert into public.providers(owner_user_id, display_name, slug, bio, status, verification_status, service_radius_km, service_area_labels)
  values (actor_id, trim(provider_display_name), lower(trim(provider_slug)), nullif(trim(provider_bio), ''), 'pending_verification', 'pending', coverage_radius_km, coalesce(coverage_labels, '{}'))
  returning id into new_provider_id;

  insert into public.provider_members(provider_id, user_id, role, status)
  values (new_provider_id, actor_id, 'owner', 'active');

  insert into public.provider_services(provider_id, service_id, title, pricing_type, base_price, status)
  values (new_provider_id, catalog_service_id, trim(listing_title), listing_pricing_type, listing_base_price, 'active');

  foreach weekday_value in array coalesce(available_weekdays, '{}') loop
    insert into public.provider_availability(provider_id, weekday, starts_at, ends_at, capacity)
    values (new_provider_id, weekday_value, available_starts_at, available_ends_at, 1);
  end loop;

  insert into public.verification_cases(subject_user_id, provider_id, kind, status)
  values (actor_id, new_provider_id, verification_kind, 'manual_review')
  returning id into new_verification_case_id;

  insert into public.files(owner_user_id, bucket, object_path, original_name, mime_type, size_bytes, scan_status, classification)
  values (actor_id, 'compliance-documents', verification_document_path, verification_document_name, verification_document_mime, verification_document_size, 'pending', 'restricted')
  returning id into new_file_id;

  insert into public.compliance_documents(verification_case_id, file_id, document_type, status)
  values (new_verification_case_id, new_file_id, verification_document_type, 'pending');

  insert into public.audit_logs(actor_user_id, actor_type, action, resource_type, resource_id, correlation_id, metadata)
  values (actor_id, 'user', 'provider.onboarding_submitted', 'provider', new_provider_id::text, coalesce(nullif(request_correlation_id,''), gen_random_uuid()::text), jsonb_build_object('verification_kind', verification_kind));

  return new_provider_id;
end;
$$;

create or replace function public.review_provider_verification(
  verification_case_id uuid,
  decision text,
  decision_reason text,
  request_correlation_id text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid());
  target_provider_id uuid;
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if not (private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')) then
    raise exception 'insufficient role' using errcode = '42501';
  end if;
  if coalesce((select auth.jwt() ->> 'aal'), '') <> 'aal2' then
    raise exception 'aal2 required' using errcode = '42501';
  end if;
  if decision not in ('approved','rejected') or length(trim(decision_reason)) < 8 then
    raise exception 'decision and reason are required' using errcode = '22023';
  end if;

  select provider_id into target_provider_id
  from public.verification_cases
  where id = $1 and status in ('pending','processing','manual_review')
  for update;
  if target_provider_id is null then raise exception 'reviewable case not found' using errcode = 'P0002'; end if;
  if decision = 'approved' and not exists (
    select 1 from public.compliance_documents d join public.files f on f.id = d.file_id
    where d.verification_case_id = $1 and f.scan_status = 'clean'
  ) then raise exception 'clean document scan required' using errcode = '42501'; end if;

  update public.verification_cases
  set status = decision, decision_reason = trim(decision_reason), reviewed_by = actor_id, decided_at = now()
  where id = $1;

  update public.providers
  set verification_status = case when decision = 'approved' then 'verified' else 'rejected' end,
      status = case when decision = 'approved' then 'active' else 'rejected' end,
      updated_at = now()
  where id = target_provider_id;

  insert into public.audit_logs(actor_user_id, actor_type, action, resource_type, resource_id, reason, correlation_id, metadata)
  values (actor_id, 'staff', 'provider.verification_' || decision, 'verification_case', $1::text, trim(decision_reason), coalesce(nullif(request_correlation_id,''), gen_random_uuid()::text), jsonb_build_object('provider_id', target_provider_id));
end;
$$;

create or replace function public.record_compliance_document_scan(
  compliance_file_id uuid,
  scan_result text,
  scan_reason text,
  request_correlation_id text
) returns void
language plpgsql security definer set search_path = '' as $$
declare actor_id uuid := (select auth.uid());
begin
  if actor_id is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if not (private.has_platform_role('admin') or private.has_platform_role('compliance') or private.has_platform_role('super_admin')) then raise exception 'insufficient role' using errcode = '42501'; end if;
  if coalesce((select auth.jwt() ->> 'aal'), '') <> 'aal2' then raise exception 'aal2 required' using errcode = '42501'; end if;
  if scan_result not in ('clean','infected','failed') or length(trim(scan_reason)) < 8 then raise exception 'scan result and reason are required' using errcode = '22023'; end if;
  if not exists (select 1 from public.compliance_documents where file_id = $1) then raise exception 'compliance file not found' using errcode = 'P0002'; end if;
  update public.files set scan_status = scan_result where id = $1 and bucket = 'compliance-documents';
  update public.compliance_documents set status = case when scan_result = 'infected' then 'rejected' else 'pending' end where file_id = $1;
  insert into public.audit_logs(actor_user_id, actor_type, action, resource_type, resource_id, reason, correlation_id, metadata)
  values (actor_id, 'staff', 'compliance.document_scan_' || scan_result, 'file', $1::text, trim(scan_reason), coalesce(nullif(request_correlation_id,''), gen_random_uuid()::text), '{}'::jsonb);
end;
$$;

revoke all on function public.submit_provider_onboarding(text,text,text,text,uuid,text,text,bigint,text[],numeric,smallint[],time,time,text,text,text,bigint,text,text) from public;
revoke all on function public.review_provider_verification(uuid,text,text,text) from public;
revoke all on function public.record_compliance_document_scan(uuid,text,text,text) from public;
grant execute on function public.submit_provider_onboarding(text,text,text,text,uuid,text,text,bigint,text[],numeric,smallint[],time,time,text,text,text,bigint,text,text) to authenticated;
grant execute on function public.review_provider_verification(uuid,text,text,text) to authenticated;
grant execute on function public.record_compliance_document_scan(uuid,text,text,text) to authenticated;

commit;

-- ============================================================================
-- 0005_catalog_seed.sql
-- ============================================================================
begin;

insert into public.categories(id, name, slug, description, sort_order, status) values
  ('51000000-0000-0000-0000-000000000001', 'Perbaikan rumah', 'perbaikan-rumah', 'Perawatan dan perbaikan hunian', 10, 'active'),
  ('51000000-0000-0000-0000-000000000002', 'Kebersihan', 'kebersihan', 'Kebersihan rumah dan tempat usaha', 20, 'active'),
  ('51000000-0000-0000-0000-000000000003', 'Konstruksi', 'konstruksi', 'Renovasi dan pekerjaan konstruksi', 30, 'active'),
  ('51000000-0000-0000-0000-000000000004', 'Jasa digital', 'jasa-digital', 'Desain dan teknologi untuk bisnis', 40, 'active')
on conflict (slug) do nothing;

insert into public.services(id, category_id, name, slug, description, default_duration_minutes, status) values
  ('52000000-0000-0000-0000-000000000001', (select id from public.categories where slug = 'perbaikan-rumah'), 'Servis AC', 'servis-ac', 'Pemeriksaan, cuci, dan perbaikan AC', 90, 'active'),
  ('52000000-0000-0000-0000-000000000002', (select id from public.categories where slug = 'perbaikan-rumah'), 'Perbaikan listrik', 'perbaikan-listrik', 'Instalasi dan gangguan listrik ringan', 120, 'active'),
  ('52000000-0000-0000-0000-000000000003', (select id from public.categories where slug = 'perbaikan-rumah'), 'Perbaikan pipa', 'perbaikan-pipa', 'Kebocoran, sumbatan, dan instalasi air', 120, 'active'),
  ('52000000-0000-0000-0000-000000000004', (select id from public.categories where slug = 'kebersihan'), 'Kebersihan rumah', 'kebersihan-rumah', 'Pembersihan rutin dan mendalam', 180, 'active'),
  ('52000000-0000-0000-0000-000000000005', (select id from public.categories where slug = 'konstruksi'), 'Renovasi ruang', 'renovasi-ruang', 'Renovasi ruang hunian dan usaha', null, 'active'),
  ('52000000-0000-0000-0000-000000000006', (select id from public.categories where slug = 'jasa-digital'), 'Desain grafis', 'desain-grafis', 'Desain identitas dan materi komunikasi', null, 'active')
on conflict (slug) do nothing;

commit;

-- ============================================================================
-- 0006_transaction_pilot.sql
-- ============================================================================
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

-- ============================================================================
-- 0007_trust_business_privacy.sql
-- ============================================================================
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

-- ============================================================================
-- 0008_ai_realtime_mvp.sql
-- ============================================================================
begin;

create table public.moderation_cases (
  id uuid primary key default gen_random_uuid(),
  subject_type text not null check (subject_type in ('review','message')),
  subject_id uuid not null,
  status text not null default 'open' check (status in ('open','allowed','blocked','appealed','closed')),
  labels text[] not null default '{}',
  confidence numeric(6,5) not null check (confidence between 0 and 1),
  evidence jsonb not null default '{}',
  assigned_to uuid references public.profiles(id),
  resolution_reason text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.moderation_cases enable row level security;
grant select on public.moderation_cases to authenticated;
create policy moderation_staff_read on public.moderation_cases for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);

revoke insert on public.messages from authenticated;
revoke insert,update on public.reviews from authenticated;

create or replace function public.suggest_job_intake(p_description text,p_service_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());service_row public.services;run_id uuid;prediction_id uuid;confidence numeric(6,5);p50 bigint;result jsonb;matched boolean:=false;
begin
 if actor_id is null or length(trim(p_description))<12 then raise exception 'description too short' using errcode='22023';end if;
 if p_service_id is not null then select * into service_row from public.services where id=p_service_id and status='active';matched:=service_row.id is not null;end if;
 if service_row.id is null then select * into service_row from public.services where status='active' and lower(p_description) like '%'||lower(name)||'%' order by sort_order,id limit 1;matched:=service_row.id is not null;end if;
 if service_row.id is null then select * into service_row from public.services where status='active' order by sort_order,id limit 1;end if;
 if service_row.id is null then raise exception 'active service unavailable' using errcode='P0002';end if;
 select coalesce(percentile_disc(0.5) within group(order by base_price),250000)::bigint into p50 from public.provider_services where service_id=service_row.id and status='active' and base_price is not null;
 confidence:=case when matched then 0.62 else 0.32 end;
 insert into public.ai_runs(module,subject_type,model_provider,model_version,prompt_version,schema_version,status,input_hash,trace_id,completed_at)
 values('smart_intake','user', 'deterministic_baseline','baseline-v1','intake-id-v1','1','fallback',pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(trim(p_description),'UTF8')),'hex'),gen_random_uuid()::text,now()) returning id into run_id;
 result:=jsonb_build_object('serviceId',service_row.id,'title',left(trim(p_description),80),'budgetMin',greatest(0,(p50*70)/100),'budgetMax',(p50*140)/100,'durationMinutes',coalesce(service_row.default_duration_minutes,120),'confidence',confidence,'mode','safe_fallback','assumptions',jsonb_build_array('Harga memakai median katalog aktif','Jadwal dan detail tetap harus dikonfirmasi pengguna'));
 insert into public.ai_predictions(ai_run_id,prediction_type,output,confidence,explanation,accepted_by) values(run_id,'structured_intake',result-'title',confidence,jsonb_build_object('reason_codes',case when matched then jsonb_build_array('service_term_match','catalog_price_baseline') else jsonb_build_array('manual_service_confirmation','catalog_price_baseline') end),actor_id) returning id into prediction_id;
 return result||jsonb_build_object('predictionId',prediction_id);
end;$$;

create or replace function public.send_moderated_message(p_conversation_id uuid,p_client_id uuid,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());message_id uuid;unsafe boolean;safe_body text;moderation_status text;
begin
 if actor_id is null or length(trim(p_body))<1 or length(p_body)>4000 or not exists(select 1 from public.conversation_participants where conversation_id=p_conversation_id and user_id=actor_id and left_at is null) then raise exception 'message denied' using errcode='42501';end if;
 unsafe:=lower(p_body) ~ '(ancam|bunuh|penipuan|nomor kartu|kata sandi)';safe_body:=case when unsafe then '[Pesan ditahan untuk pemeriksaan moderasi]' else trim(p_body) end;moderation_status:=case when unsafe then 'flagged' else 'allowed' end;
 insert into public.messages(conversation_id,sender_user_id,client_id,kind,body,moderation_status) values(p_conversation_id,actor_id,p_client_id,'text',safe_body,moderation_status) returning id into message_id;
 if unsafe then insert into public.moderation_cases(subject_type,subject_id,labels,confidence,evidence) values('message',message_id,array['safety_or_sensitive_data'],0.88,jsonb_build_object('detector','rules-id-v1'));end if;
 return message_id;
end;$$;

create or replace function public.publish_tracking_point(p_booking_id uuid,p_latitude double precision,p_longitude double precision,p_accuracy numeric,p_captured_at timestamptz)
returns bigint language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());point_id bigint;b public.bookings;
begin
 select * into b from public.bookings where id=p_booking_id and status in('en_route','in_progress');
 if b.id is null or not private.is_provider_member(b.provider_id,array['owner','dispatcher','technician']) or p_latitude not between -11.5 and 6.5 or p_longitude not between 94 and 142 or p_accuracy<0 or p_accuracy>5000 or p_captured_at>now()+interval '2 minutes' then raise exception 'tracking point denied' using errcode='42501';end if;
 insert into public.tracking_points(booking_id,provider_user_id,location,accuracy_meters,captured_at) values(b.id,actor_id,public.st_setsrid(public.st_makepoint(p_longitude,p_latitude),4326)::public.geography,p_accuracy,p_captured_at) returning id into point_id;
 return point_id;
end;$$;

create or replace function public.resolve_moderation_case(p_case_id uuid,p_decision text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());c public.moderation_cases;
begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'moderator AAL2 required' using errcode='42501';end if;
 if p_decision not in('allowed','blocked') or length(trim(p_reason))<10 then raise exception 'reasoned moderation decision required' using errcode='22023';end if;
 select * into c from public.moderation_cases where id=p_case_id and status in('open','appealed') for update;if c.id is null then raise exception 'active moderation case not found' using errcode='P0002';end if;
 update public.moderation_cases set status=p_decision,assigned_to=actor_id,resolution_reason=trim(p_reason),resolved_at=now() where id=c.id;
 if c.subject_type='review' then
  update public.reviews set status=case when p_decision='allowed' then 'published' else 'removed' end,updated_at=now() where id=c.subject_id;
  update public.providers p set rating_avg=(select avg(r.rating)::numeric(3,2) from public.reviews r where r.provider_id=p.id and r.status='published'),rating_count=(select count(*) from public.reviews r where r.provider_id=p.id and r.status='published'),updated_at=now() where p.id=(select provider_id from public.reviews where id=c.subject_id);
 else update public.messages set moderation_status=case when p_decision='allowed' then 'allowed' else 'blocked' end where id=c.subject_id;end if;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','moderation.'||p_decision,'moderation_case',c.id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function public.submit_verified_review(p_booking_id uuid,p_rating smallint,p_title text,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());b public.bookings;new_id uuid;unsafe boolean;
begin
 select * into b from public.bookings where id=p_booking_id and customer_id=actor_id and status in('customer_confirmed','closed','resolved');if b.id is null or p_rating not between 1 and 5 then raise exception 'review not eligible' using errcode='22023';end if;
 unsafe:=lower(coalesce(p_title,'')||' '||coalesce(p_body,'')) ~ '(ancam|bunuh|penipuan|nomor kartu|kata sandi)';
 insert into public.reviews(booking_id,customer_id,provider_id,rating,title,body,status,moderation) values(b.id,actor_id,b.provider_id,p_rating,nullif(trim(p_title),''),nullif(trim(p_body),''),case when unsafe then 'flagged' else 'published' end,jsonb_build_object('detector','rules-id-v1','confidence',case when unsafe then 0.88 else 0.70 end)) returning id into new_id;
 if unsafe then insert into public.moderation_cases(subject_type,subject_id,labels,confidence,evidence) values('review',new_id,array['safety_or_sensitive_data'],0.88,jsonb_build_object('detector','rules-id-v1'));else update public.providers set rating_avg=(select avg(rating)::numeric(3,2) from public.reviews where provider_id=b.provider_id and status='published'),rating_count=(select count(*) from public.reviews where provider_id=b.provider_id and status='published'),updated_at=now() where id=b.provider_id;end if;
 return new_id;
end;$$;

do $$begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='messages') then alter publication supabase_realtime add table public.messages;end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tracking_points') then alter publication supabase_realtime add table public.tracking_points;end if;
end$$;

revoke all on function public.suggest_job_intake(text,uuid),public.send_moderated_message(uuid,uuid,text),public.publish_tracking_point(uuid,double precision,double precision,numeric,timestamptz),public.resolve_moderation_case(uuid,text,text,text) from public;
grant execute on function public.suggest_job_intake(text,uuid),public.send_moderated_message(uuid,uuid,text),public.publish_tracking_point(uuid,double precision,double precision,numeric,timestamptz),public.resolve_moderation_case(uuid,text,text,text) to authenticated;

commit;

-- ============================================================================
-- 0009_launch_controls.sql
-- ============================================================================
begin;

create table public.platform_feature_flags (
  name text primary key check (name in ('booking_intake','payment_capture','payout_release','ai_intake','tracking_publish')),
  enabled boolean not null default true,
  reason text not null default 'Initial launch setting',
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

insert into public.platform_feature_flags(name) values('booking_intake'),('payment_capture'),('payout_release'),('ai_intake'),('tracking_publish');
alter table public.platform_feature_flags enable row level security;
grant select on public.platform_feature_flags to authenticated;
create policy launch_flags_staff_read on public.platform_feature_flags for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);

create or replace function private.require_feature_enabled()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if not coalesce((select enabled from public.platform_feature_flags where name=tg_argv[0]),false) then raise exception 'feature temporarily disabled: %',tg_argv[0] using errcode='55000';end if;
 return new;
end;$$;
revoke all on function private.require_feature_enabled() from public;

create trigger guard_booking_intake before insert on public.jobs for each row execute function private.require_feature_enabled('booking_intake');
create trigger guard_payment_capture before update of status on public.payment_intents for each row when (new.status='captured' and old.status is distinct from new.status) execute function private.require_feature_enabled('payment_capture');
create trigger guard_payout_release before insert on public.payouts for each row execute function private.require_feature_enabled('payout_release');
create trigger guard_ai_intake before insert on public.ai_runs for each row when (new.module='smart_intake') execute function private.require_feature_enabled('ai_intake');
create trigger guard_tracking_publish before insert on public.tracking_points for each row execute function private.require_feature_enabled('tracking_publish');

create or replace function public.set_platform_feature_flag(p_name text,p_enabled boolean,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());old_value boolean;
begin
 if not(private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'admin AAL2 required' using errcode='42501';end if;
 if length(trim(p_reason))<10 then raise exception 'control reason required' using errcode='22023';end if;
 select enabled into old_value from public.platform_feature_flags where name=p_name for update;if old_value is null then raise exception 'unknown feature flag' using errcode='22023';end if;
 update public.platform_feature_flags set enabled=p_enabled,reason=trim(p_reason),updated_by=actor_id,updated_at=now() where name=p_name;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,before_hash,after_hash,correlation_id) values(actor_id,'staff','launch.feature_flag_changed','platform_feature_flag',p_name,trim(p_reason),old_value::text,p_enabled::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function public.get_launch_metrics()
returns jsonb language plpgsql security definer set search_path='' stable as $$
begin
 if not(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'operations AAL2 required' using errcode='42501';end if;
 return jsonb_build_object(
  'activeBookings',(select count(*) from public.bookings where status in('confirmed','accepted','en_route','in_progress','provider_completed')),
  'openDisputes',(select count(*) from public.disputes where status not in('resolved','closed')),
  'pendingRefunds',(select count(*) from public.refunds where status='requested'),
  'openModeration',(select count(*) from public.moderation_cases where status in('open','appealed')),
  'outboxBacklog',(select count(*) from public.outbox_events where published_at is null and available_at<=now()),
  'aiFallback24h',(select count(*) from public.ai_runs where status='fallback' and created_at>=now()-interval '24 hours')
 );
end;$$;

revoke all on function public.set_platform_feature_flag(text,boolean,text,text),public.get_launch_metrics() from public;
grant execute on function public.set_platform_feature_flag(text,boolean,text,text),public.get_launch_metrics() to authenticated;

commit;

-- ============================================================================
-- 0010_scale_foundation.sql
-- ============================================================================
begin;

create table public.ranking_model_versions (
  id uuid primary key default gen_random_uuid(), name text not null unique, status text not null check(status in('shadow','canary','active','retired')),
  traffic_percent smallint not null default 0 check(traffic_percent between 0 and 100), feature_schema text not null,
  weights jsonb not null, evaluation jsonb not null default '{}', created_at timestamptz not null default now(), activated_at timestamptz
);
insert into public.ranking_model_versions(name,status,traffic_percent,feature_schema,weights,evaluation,activated_at) values('deterministic-rules-v1','active',100,'ranking.v1','{"relevance":0.30,"rating":0.25,"response":0.20,"experience":0.15,"area":0.10}','{"baseline":true}',now());

create table public.demand_forecasts (
  id uuid primary key default gen_random_uuid(), service_id uuid references public.services(id), region_code text not null default 'ID',
  horizon_start date not null, horizon_end date not null, p10 numeric(12,2) not null, p50 numeric(12,2) not null, p90 numeric(12,2) not null,
  model_version text not null, drivers jsonb not null default '{}', created_at timestamptz not null default now(), check(p10<=p50 and p50<=p90)
);
alter table public.ranking_model_versions enable row level security;alter table public.demand_forecasts enable row level security;
grant select on public.ranking_model_versions,public.demand_forecasts,public.fraud_signals,public.fraud_cases to authenticated;
create policy scale_models_staff_read on public.ranking_model_versions for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy forecasts_staff_read on public.demand_forecasts for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy fraud_signals_staff_read on public.fraud_signals for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy fraud_cases_staff_read on public.fraud_cases for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));

create or replace function public.submit_emergency_job_request(p_service_id uuid,p_title text,p_description text,p_budget_max bigint,p_safety_confirmed boolean,p_idempotency_key text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());new_id uuid;existing_id uuid;
begin
 if actor_id is null then raise exception 'authentication required' using errcode='28000';end if;
 select resource_id into existing_id from public.idempotency_keys where principal_id=actor_id and scope='job.emergency' and key=p_idempotency_key and expires_at>now();if existing_id is not null then return existing_id;end if;
 if not p_safety_confirmed or length(trim(p_title))<5 or length(trim(p_description))<20 or p_budget_max<=0 then raise exception 'emergency request incomplete' using errcode='22023';end if;
 if not exists(select 1 from public.services where id=p_service_id and status='active' and emergency_enabled) then raise exception 'service not enabled for emergency dispatch' using errcode='22023';end if;
 insert into public.jobs(customer_id,service_id,title,description,booking_type,status,requested_start,requested_end,budget_min,budget_max) values(actor_id,p_service_id,trim(p_title),trim(p_description),'emergency','requested',now()+interval '15 minutes',now()+interval '4 hours',0,p_budget_max) returning id into new_id;
 insert into public.job_matches(job_id,provider_id,provider_service_id,rank,score,score_components,reason_codes,model_version,status)
 select new_id,ps.provider_id,ps.id,row_number() over(order by p.response_rate desc,p.rating_avg desc,p.id)::integer,least(1,(p.response_rate/100*0.55+p.rating_avg/5*0.45))::numeric(8,5),jsonb_build_object('response_rate',p.response_rate,'rating',p.rating_avg),array['emergency_enabled','verified_provider','response_priority'],'emergency-rules-v1','invited' from public.provider_services ps join public.providers p on p.id=ps.provider_id where ps.service_id=p_service_id and ps.status='active' and p.status='active' and p.verification_status='verified' order by p.response_rate desc,p.rating_avg desc limit 5;
 if exists(select 1 from public.job_matches where job_id=new_id) then update public.jobs set status='matched' where id=new_id;end if;
 insert into public.notifications(user_id,event_type,channel,template_version,payload)
 select p.owner_user_id,'emergency.job_invited',channel,'v1',jsonb_build_object('job_id',new_id) from public.job_matches m join public.providers p on p.id=m.provider_id cross join lateral (select 'in_app'::text channel union all select np.channel from public.notification_preferences np where np.user_id=p.owner_user_id and np.event_type='emergency.job_invited' and np.enabled and np.channel in('email','push','whatsapp','sms')) c where m.job_id=new_id;
 insert into public.idempotency_keys(principal_id,scope,key,request_hash,response_status,resource_id,expires_at) values(actor_id,'job.emergency',p_idempotency_key,pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(concat_ws('|',p_service_id,p_title,p_budget_max),'UTF8')),'hex'),201,new_id,now()+interval '24 hours');
 insert into public.outbox_events(aggregate_type,aggregate_id,event_type,payload,correlation_id) values('job',new_id,'emergency.dispatch_requested',jsonb_build_object('job_id',new_id),p_idempotency_key);return new_id;
end;$$;

create or replace function public.record_manual_fraud_signal(p_user_id uuid,p_booking_id uuid,p_signal_type text,p_score numeric,p_reason text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());new_id uuid;begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud reviewer AAL2 required' using errcode='42501';end if;
 if p_score not between 0 and 1 or length(trim(p_reason))<10 or p_user_id is null then raise exception 'invalid fraud signal' using errcode='22023';end if;
 insert into public.fraud_signals(user_id,booking_id,signal_type,source,score,payload,expires_at) values(p_user_id,p_booking_id,p_signal_type,'manual_review',p_score,jsonb_build_object('reason',trim(p_reason)),now()+interval '90 days') returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','fraud.signal_recorded','fraud_signal',new_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;end;$$;

create or replace function public.open_fraud_case(p_user_id uuid,p_booking_id uuid,p_reason text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());risk numeric;new_id uuid;begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud reviewer AAL2 required' using errcode='42501';end if;
 if length(trim(p_reason))<10 then raise exception 'case reason required' using errcode='22023';end if;
 select least(100,coalesce(sum(score*100),0)) into risk from public.fraud_signals where user_id=p_user_id and (p_booking_id is null or booking_id=p_booking_id) and (expires_at is null or expires_at>now());if risk=0 then raise exception 'no active signals' using errcode='22023';end if;
 insert into public.fraud_cases(subject_user_id,booking_id,risk_score,severity,status) values(p_user_id,p_booking_id,risk,case when risk>=80 then 'critical' when risk>=60 then 'high' when risk>=30 then 'medium' else 'low' end,'open') returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id,metadata) values(actor_id,'staff','fraud.case_opened','fraud_case',new_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text),jsonb_build_object('risk_score',risk));return new_id;end;$$;

create or replace function public.decide_fraud_case(p_case_id uuid,p_decision text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());begin
 if not(private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud decision AAL2 required' using errcode='42501';end if;
 if p_decision not in('cleared','confirmed') or length(trim(p_reason))<10 then raise exception 'reasoned fraud decision required' using errcode='22023';end if;
 update public.fraud_cases set status=p_decision,assigned_to=actor_id,decision_reason=trim(p_reason),closed_at=now() where id=p_case_id and status in('open','reviewing','appealed');if not found then raise exception 'active fraud case not found' using errcode='P0002';end if;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','fraud.case_'||p_decision,'fraud_case',p_case_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));end;$$;

create or replace function public.refresh_demand_forecast(p_service_id uuid,p_region_code text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());daily numeric;new_id uuid;begin
 if not(private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'forecast admin AAL2 required' using errcode='42501';end if;
 select coalesce(count(*)::numeric/28,0) into daily from public.jobs where service_id=p_service_id and created_at>=now()-interval '28 days';
 insert into public.demand_forecasts(service_id,region_code,horizon_start,horizon_end,p10,p50,p90,model_version,drivers) values(p_service_id,upper(p_region_code),current_date+1,current_date+7,greatest(0,daily*7*0.65),daily*7,daily*7*1.45,'historical-baseline-v1',jsonb_build_object('history_days',28,'method','daily_average')) returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,correlation_id) values(actor_id,'staff','forecast.refreshed','demand_forecast',new_id::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;end;$$;

revoke all on function public.submit_emergency_job_request(uuid,text,text,bigint,boolean,text),public.record_manual_fraud_signal(uuid,uuid,text,numeric,text,text),public.open_fraud_case(uuid,uuid,text,text),public.decide_fraud_case(uuid,text,text,text),public.refresh_demand_forecast(uuid,text,text) from public;
grant execute on function public.submit_emergency_job_request(uuid,text,text,bigint,boolean,text),public.record_manual_fraud_signal(uuid,uuid,text,numeric,text,text),public.open_fraud_case(uuid,uuid,text,text),public.decide_fraud_case(uuid,text,text,text),public.refresh_demand_forecast(uuid,text,text) to authenticated;

commit;
