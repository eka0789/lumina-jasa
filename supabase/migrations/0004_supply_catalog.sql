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
