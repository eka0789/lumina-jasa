begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

select ok(
  (select bool_and(c.relrowsecurity)
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r'),
  'RLS is enabled on every public table'
);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('10000000-0000-0000-0000-000000000001', 'member-a@example.test', '', now(), '{}', '{"full_name":"Member A"}', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-000000000002', 'member-b@example.test', '', now(), '{}', '{"full_name":"Member B"}', 'authenticated', 'authenticated'),
  ('10000000-0000-0000-0000-000000000003', 'outsider@example.test', '', now(), '{}', '{"full_name":"Outsider"}', 'authenticated', 'authenticated');

insert into public.businesses (id, legal_name, display_name, created_by)
values
  ('20000000-0000-0000-0000-000000000001', 'Tenant A PT', 'Tenant A', '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 'Tenant B PT', 'Tenant B', '10000000-0000-0000-0000-000000000002');

insert into public.business_members (business_id, user_id, role)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'owner'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'owner');

insert into public.providers (id, owner_user_id, display_name, slug, status, verification_status)
values
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Provider Publik', 'provider-publik', 'active', 'verified'),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Provider Draft', 'provider-draft', 'draft', 'unverified');

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
select is((select count(*)::integer from public.businesses), 1, 'member can read exactly one business');
select is((select display_name::text from public.businesses), 'Tenant A', 'member reads own tenant');
select is((select count(*)::integer from public.businesses where id = '20000000-0000-0000-0000-000000000002'), 0, 'member cannot read another tenant');
select lives_ok(
  $$insert into public.addresses (user_id, address_line1, city, province) values ('10000000-0000-0000-0000-000000000001', 'Jalan Sendiri', 'Jakarta', 'DKI Jakarta')$$,
  'member can insert own address'
);
select throws_ok(
  $$insert into public.addresses (user_id, address_line1, city, province) values ('10000000-0000-0000-0000-000000000002', 'Jalan Tenant Lain', 'Bandung', 'Jawa Barat')$$,
  '42501', 'new row violates row-level security policy for table "addresses"',
  'member cannot insert another user address'
);

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000003', true);
select is((select count(*)::integer from public.businesses), 0, 'outsider cannot read tenant data');

reset role;
set local role anon;
select is((select count(*)::integer from public.providers), 1, 'anonymous user sees only active verified providers');

select * from finish();
rollback;
