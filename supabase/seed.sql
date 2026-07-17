-- =============================================================================
-- LUMINA JASA — SEED DATA (Local / Development Only)
-- All passwords: password123
-- =============================================================================
-- Platform roles: customer, support, finance, compliance, ai_moderator, admin, super_admin
-- Provider roles: owner, manager, worker
-- Business roles: owner, admin, requester, approver, viewer
-- =============================================================================

-- Local/test-only switches.
SELECT set_config('app.environment', 'development', false);

-- =============================================================================
-- AUTH USERS (semua role)
-- UUID range: 00000000-0000-0000-0000-0000000000xx
-- =============================================================================
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES
  -- 01: Customer biasa
  ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'customer@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Budi Santoso"}',
   now(),now(),'','','',''),

  -- 02: Provider (pemilik usaha jasa)
  ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'provider@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Andi Wijaya"}',
   now(),now(),'','','',''),

  -- 03: Support staff
  ('00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'support@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Siti Rahayu"}',
   now(),now(),'','','',''),

  -- 04: Finance staff
  ('00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'finance@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Reza Pratama"}',
   now(),now(),'','','',''),

  -- 05: Compliance staff
  ('00000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'compliance@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Dewi Kusuma"}',
   now(),now(),'','','',''),

  -- 06: AI Moderator
  ('00000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'aimod@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"AI Moderator Bot"}',
   now(),now(),'','','',''),

  -- 07: Admin platform
  ('00000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'admin@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Admin Platform"}',
   now(),now(),'','','',''),

  -- 08: Super Admin
  ('00000000-0000-0000-0000-000000000008','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'superadmin@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Super Admin"}',
   now(),now(),'','','',''),

  -- 09: Provider Manager (karyawan penyedia jasa)
  ('00000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'manager@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Hendra Manajer"}',
   now(),now(),'','','',''),

  -- 10: Provider Worker (teknisi lapangan)
  ('00000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'worker@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Fajar Teknisi"}',
   now(),now(),'','','',''),

  -- 11: Business Owner (pemilik akun bisnis korporat)
  ('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'bizowner@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Tono Bisnis Owner"}',
   now(),now(),'','','',''),

  -- 12: Business Requester (staf yang bisa buat permintaan jasa)
  ('00000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
   'bizrequester@example.com', crypt('password123',gen_salt('bf')),
   now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Maya Requester"}',
   now(),now(),'','','','')
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- AUTH IDENTITIES
-- =============================================================================
INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT
  gen_random_uuid(), id::text, id,
  format('{"sub":"%s","email":"%s"}', id, email)::jsonb,
  'email', now(), now(), now()
FROM auth.users
WHERE id IN (
  '00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000006',
  '00000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000008',
  '00000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000012'
)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PLATFORM ROLES (user_roles)
-- =============================================================================
INSERT INTO public.user_roles (user_id, role) VALUES
  -- Customer (semua user dapat peran customer secara default)
  ('00000000-0000-0000-0000-000000000001', 'customer'),
  ('00000000-0000-0000-0000-000000000002', 'customer'),
  ('00000000-0000-0000-0000-000000000009', 'customer'),
  ('00000000-0000-0000-0000-000000000010', 'customer'),
  ('00000000-0000-0000-0000-000000000011', 'customer'),
  ('00000000-0000-0000-0000-000000000012', 'customer'),
  -- Staff roles
  ('00000000-0000-0000-0000-000000000003', 'support'),
  ('00000000-0000-0000-0000-000000000004', 'finance'),
  ('00000000-0000-0000-0000-000000000005', 'compliance'),
  ('00000000-0000-0000-0000-000000000006', 'ai_moderator'),
  ('00000000-0000-0000-0000-000000000007', 'admin'),
  ('00000000-0000-0000-0000-000000000008', 'super_admin'),
  -- Admin juga dapat support & finance untuk akses penuh
  ('00000000-0000-0000-0000-000000000007', 'support'),
  ('00000000-0000-0000-0000-000000000007', 'finance'),
  ('00000000-0000-0000-0000-000000000008', 'admin'),
  ('00000000-0000-0000-0000-000000000008', 'support'),
  ('00000000-0000-0000-0000-000000000008', 'finance'),
  ('00000000-0000-0000-0000-000000000008', 'compliance')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PROVIDER (usaha jasa — dimiliki oleh akun 02)
-- =============================================================================
INSERT INTO public.providers (id, owner_user_id, display_name, slug, bio, status, verification_status,
  rating_avg, rating_count, completed_jobs, response_rate, created_at, updated_at)
VALUES (
  'aa000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  'Sejuk AC Services',
  'sejuk-ac-services',
  'Spesialis perbaikan dan perawatan AC rumah & komersial. Berpengalaman 10 tahun, teknisi bersertifikat.',
  'active', 'verified',
  4.85, 120, 310, 97.5,
  now(), now()
) ON CONFLICT DO NOTHING;

-- Provider members: owner=02, manager=09, worker=10
INSERT INTO public.provider_members (provider_id, user_id, role, status) VALUES
  ('aa000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','owner','active'),
  ('aa000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000009','manager','active'),
  ('aa000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000010','worker','active')
ON CONFLICT DO NOTHING;

-- Provider service
INSERT INTO public.provider_services (id, provider_id, service_id, title, pricing_type, base_price, status)
VALUES (
  'bb000000-0000-0000-0000-000000000001',
  'aa000000-0000-0000-0000-000000000001',
  '52000000-0000-0000-0000-000000000001',
  'Servis & Cuci AC Standar',
  'fixed', 150000, 'active'
) ON CONFLICT DO NOTHING;

-- =============================================================================
-- BUSINESS (akun korporat — dimiliki oleh akun 11)
-- =============================================================================
INSERT INTO public.businesses (id, legal_name, display_name, tax_id, verification_status,
  billing_email, created_by, created_at, updated_at)
VALUES (
  'cc000000-0000-0000-0000-000000000001',
  'PT Maju Bersama Indonesia',
  'Maju Bersama',
  '01.234.567.8-901.000',
  'verified',
  'billing@majubersama.co.id',
  '00000000-0000-0000-0000-000000000011',
  now(), now()
) ON CONFLICT DO NOTHING;

-- Business members
INSERT INTO public.business_members (business_id, user_id, role, status) VALUES
  ('cc000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000011','owner','active'),
  ('cc000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000012','requester','active'),
  -- customer biasa juga masuk sebagai viewer untuk demo
  ('cc000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','viewer','active')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- JOB (permintaan jasa dari customer 01)
-- =============================================================================
INSERT INTO public.jobs (id, customer_id, service_id, title, description, booking_type, status)
VALUES (
  'dd000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '52000000-0000-0000-0000-000000000001',
  'AC kamar tidak dingin',
  'AC kamar tidur saya tidak mengeluarkan udara dingin sejak kemarin. Perlu dicek freon dan dibersihkan.',
  'scheduled', 'requested'
) ON CONFLICT DO NOTHING;

-- Job match (provider 'Sejuk AC' diundang untuk mengerjakan)
INSERT INTO public.job_matches (job_id, provider_id, provider_service_id, rank, score, score_components, status, model_version)
VALUES (
  'dd000000-0000-0000-0000-000000000001',
  'aa000000-0000-0000-0000-000000000001',
  'bb000000-0000-0000-0000-000000000001',
  1, 0.96,
  '{"relevance":0.95,"rating":0.97,"response":0.98,"experience":0.95,"area":0.90}'::jsonb,
  'invited', 'deterministic-rules-v1'
) ON CONFLICT DO NOTHING;

-- =============================================================================
-- BOOKING (pesanan yang sudah dikonfirmasi — untuk demo customer dashboard)
-- =============================================================================
INSERT INTO public.bookings (
  id, job_id, customer_id, provider_id, provider_service_id,
  assigned_user_id, status,
  scheduled_start, scheduled_end,
  subtotal, platform_fee, tax_amount, total_amount,
  policy_snapshot
) VALUES (
  'ee000000-0000-0000-0000-000000000001',
  'dd000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'aa000000-0000-0000-0000-000000000001',
  'bb000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000010', -- teknisi yang ditugaskan
  'awaiting_payment',
  now() + interval '2 days',
  now() + interval '2 days' + interval '2 hours',
  150000, 7500, 15750, 173250,
  '{"cancellation_window_hours":2,"platform_fee_pct":5,"tax_pct":11}'::jsonb
) ON CONFLICT DO NOTHING;