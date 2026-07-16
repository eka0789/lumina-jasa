begin;

create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('40000000-0000-0000-0000-000000000001', 'provider-owner@example.test', '', now(), '{}', '{"full_name":"Provider Owner"}', 'authenticated', 'authenticated'),
  ('40000000-0000-0000-0000-000000000002', 'catalog-outsider@example.test', '', now(), '{}', '{"full_name":"Catalog Outsider"}', 'authenticated', 'authenticated'),
  ('40000000-0000-0000-0000-000000000003', 'catalog-admin@example.test', '', now(), '{}', '{"full_name":"Catalog Admin"}', 'authenticated', 'authenticated');

insert into public.user_roles(user_id, role)
values ('40000000-0000-0000-0000-000000000003', 'compliance');

insert into public.categories(id, name, slug, status)
values ('41000000-0000-0000-0000-000000000001', 'Perawatan Rumah', 'perawatan-rumah-test', 'active');
insert into public.services(id, category_id, name, slug, status)
values ('42000000-0000-0000-0000-000000000001', '41000000-0000-0000-0000-000000000001', 'Servis AC', 'servis-ac-test', 'active');

set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"40000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}', true);
select lives_ok(
  $$select public.submit_provider_onboarding('Teknik Sejuk', 'teknik-sejuk-test', 'Spesialis pendingin rumah', 'kyc', '42000000-0000-0000-0000-000000000001', 'Servis AC Rumah', 'from', 250000, array['Jakarta Selatan'], 15, array[1,2,3,4,5]::smallint[], '08:00', '17:00', '40000000-0000-0000-0000-000000000001/test-identity.pdf', 'identity.pdf', 'application/pdf', 1024, 'identity', 'test-onboarding')$$,
  'authenticated user can submit provider onboarding atomically'
);
select is((select count(*)::integer from public.providers where slug = 'teknik-sejuk-test'), 1, 'owner can read pending provider profile');

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"40000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal1"}', true);
select is((select count(*)::integer from public.providers where slug = 'teknik-sejuk-test'), 0, 'outsider cannot read pending provider profile');

select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"40000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}', true);
select is((select count(*)::integer from public.providers where slug = 'teknik-sejuk-test'), 1, 'compliance user can inspect pending provider');
select lives_ok(
  $$select public.record_compliance_document_scan((select d.file_id from public.compliance_documents d join public.verification_cases v on v.id = d.verification_case_id join public.providers p on p.id = v.provider_id where p.slug = 'teknik-sejuk-test'), 'clean', 'Pemindaian antivirus manual bersih.', 'test-scan')$$,
  'compliance user records a clean document scan before approval'
);
select lives_ok(
  $$select public.review_provider_verification((select id from public.verification_cases where provider_id = (select id from public.providers where slug = 'teknik-sejuk-test')), 'approved', 'Dokumen identitas valid dan sesuai.', 'test-review')$$,
  'compliance user with AAL2 can approve provider'
);

reset role;
set local role anon;
select is((select count(*)::integer from public.providers where slug = 'teknik-sejuk-test'), 1, 'approved provider is visible in public catalog');

select * from finish();
rollback;
