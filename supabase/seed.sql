-- =============================================================================
-- LUMINA JASA - SEED DATA (20 entries per table)
-- =============================================================================
SELECT set_config('app.environment', 'development', false);
-- =============================================================================
-- AUTH USERS
-- =============================================================================
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token) VALUES
  ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user1@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 1"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user2@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 2"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user3@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 3"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user4@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 4"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user5@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 5"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user6@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 6"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user7@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 7"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000008','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user8@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 8"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user9@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 9"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user10@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 10"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user11@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 11"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user12@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 12"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user13@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 13"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000014','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user14@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 14"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000015','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user15@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 15"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000016','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user16@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 16"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000017','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user17@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 17"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000018','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user18@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 18"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000019','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user19@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 19"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000020','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user20@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 20"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user21@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 21"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000022','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user22@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 22"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000023','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user23@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 23"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000024','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user24@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 24"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000025','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user25@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 25"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000026','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user26@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 26"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000027','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user27@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 27"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000028','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user28@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 28"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000029','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user29@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 29"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000030','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user30@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 30"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000031','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user31@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 31"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000032','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user32@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 32"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000033','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user33@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 33"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000034','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user34@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 34"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000035','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user35@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 35"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000036','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user36@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 36"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000037','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user37@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 37"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000038','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user38@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 38"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000039','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user39@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 39"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000040','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user40@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 40"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user41@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 41"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user42@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 42"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user43@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 43"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000044','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user44@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 44"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000045','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user45@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 45"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000046','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user46@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 46"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000047','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user47@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 47"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000048','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user48@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 48"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000049','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user49@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 49"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000050','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user50@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 50"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user51@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 51"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user52@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 52"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000053','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user53@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 53"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000054','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user54@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 54"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000055','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user55@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 55"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000056','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user56@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 56"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000057','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user57@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 57"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000058','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user58@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 58"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000059','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user59@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 59"}', now(),now(),'','','',''),
  ('00000000-0000-0000-0000-000000000060','00000000-0000-0000-0000-000000000000','authenticated','authenticated','user60@example.com', crypt('password123',gen_salt('bf')), now(),now(),now(),'{"provider":"email","providers":["email"]}','{"full_name":"User 60"}', now(),now(),'','','','')
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- AUTH IDENTITIES
-- =============================================================================
INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), id::text, id, format('{"sub":"%s","email":"%s"}', id, email)::jsonb, 'email', now(), now(), now() FROM auth.users ON CONFLICT DO NOTHING;

-- =============================================================================
-- USER ROLES (20 roles)
-- =============================================================================
INSERT INTO public.user_roles (user_id, role) VALUES
  ('00000000-0000-0000-0000-000000000001', 'customer'),
  ('00000000-0000-0000-0000-000000000002', 'customer'),
  ('00000000-0000-0000-0000-000000000003', 'customer'),
  ('00000000-0000-0000-0000-000000000004', 'customer'),
  ('00000000-0000-0000-0000-000000000005', 'customer'),
  ('00000000-0000-0000-0000-000000000006', 'customer'),
  ('00000000-0000-0000-0000-000000000007', 'customer'),
  ('00000000-0000-0000-0000-000000000008', 'customer'),
  ('00000000-0000-0000-0000-000000000009', 'customer'),
  ('00000000-0000-0000-0000-000000000010', 'customer'),
  ('00000000-0000-0000-0000-000000000011', 'customer'),
  ('00000000-0000-0000-0000-000000000012', 'customer'),
  ('00000000-0000-0000-0000-000000000013', 'customer'),
  ('00000000-0000-0000-0000-000000000014', 'customer'),
  ('00000000-0000-0000-0000-000000000015', 'customer'),
  ('00000000-0000-0000-0000-000000000016', 'customer'),
  ('00000000-0000-0000-0000-000000000017', 'customer'),
  ('00000000-0000-0000-0000-000000000018', 'customer'),
  ('00000000-0000-0000-0000-000000000019', 'customer'),
  ('00000000-0000-0000-0000-000000000020', 'customer')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PROVIDERS (20)
-- =============================================================================
INSERT INTO public.providers (id, owner_user_id, display_name, slug, bio, status, verification_status, rating_avg, rating_count, completed_jobs, response_rate, created_at, updated_at) VALUES
  ('aa000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', 'Provider 1', 'provider-1', 'Bio provider 1', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000022', 'Provider 2', 'provider-2', 'Bio provider 2', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000023', 'Provider 3', 'provider-3', 'Bio provider 3', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000024', 'Provider 4', 'provider-4', 'Bio provider 4', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000025', 'Provider 5', 'provider-5', 'Bio provider 5', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000026', 'Provider 6', 'provider-6', 'Bio provider 6', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000027', 'Provider 7', 'provider-7', 'Bio provider 7', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000028', 'Provider 8', 'provider-8', 'Bio provider 8', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000029', 'Provider 9', 'provider-9', 'Bio provider 9', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000030', 'Provider 10', 'provider-10', 'Bio provider 10', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000031', 'Provider 11', 'provider-11', 'Bio provider 11', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000032', 'Provider 12', 'provider-12', 'Bio provider 12', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000033', 'Provider 13', 'provider-13', 'Bio provider 13', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000034', 'Provider 14', 'provider-14', 'Bio provider 14', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000035', 'Provider 15', 'provider-15', 'Bio provider 15', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000036', 'Provider 16', 'provider-16', 'Bio provider 16', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000037', 'Provider 17', 'provider-17', 'Bio provider 17', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000038', 'Provider 18', 'provider-18', 'Bio provider 18', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000039', 'Provider 19', 'provider-19', 'Bio provider 19', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now()),
  ('aa000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000040', 'Provider 20', 'provider-20', 'Bio provider 20', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now())
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PROVIDER MEMBERS (20)
-- =============================================================================
INSERT INTO public.provider_members (provider_id, user_id, role, status) VALUES
  ('aa000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000022', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000023', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000024', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000025', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000026', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000027', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000028', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000029', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000030', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000031', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000032', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000033', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000034', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000035', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000036', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000037', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000038', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000039', 'owner', 'active'),
  ('aa000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000040', 'owner', 'active')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PROVIDER SERVICES (20)
-- =============================================================================
INSERT INTO public.provider_services (id, provider_id, service_id, title, pricing_type, base_price, status) VALUES
  ('bb000000-0000-0000-0000-000000000001', 'aa000000-0000-0000-0000-000000000001', '52000000-0000-0000-0000-000000000001', 'Service 1', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000002', 'aa000000-0000-0000-0000-000000000002', '52000000-0000-0000-0000-000000000001', 'Service 2', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000003', 'aa000000-0000-0000-0000-000000000003', '52000000-0000-0000-0000-000000000001', 'Service 3', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000004', 'aa000000-0000-0000-0000-000000000004', '52000000-0000-0000-0000-000000000001', 'Service 4', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000005', 'aa000000-0000-0000-0000-000000000005', '52000000-0000-0000-0000-000000000001', 'Service 5', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000006', 'aa000000-0000-0000-0000-000000000006', '52000000-0000-0000-0000-000000000001', 'Service 6', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000007', 'aa000000-0000-0000-0000-000000000007', '52000000-0000-0000-0000-000000000001', 'Service 7', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000008', 'aa000000-0000-0000-0000-000000000008', '52000000-0000-0000-0000-000000000001', 'Service 8', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000009', 'aa000000-0000-0000-0000-000000000009', '52000000-0000-0000-0000-000000000001', 'Service 9', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000010', 'aa000000-0000-0000-0000-000000000010', '52000000-0000-0000-0000-000000000001', 'Service 10', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000011', 'aa000000-0000-0000-0000-000000000011', '52000000-0000-0000-0000-000000000001', 'Service 11', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000012', 'aa000000-0000-0000-0000-000000000012', '52000000-0000-0000-0000-000000000001', 'Service 12', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000013', 'aa000000-0000-0000-0000-000000000013', '52000000-0000-0000-0000-000000000001', 'Service 13', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000014', 'aa000000-0000-0000-0000-000000000014', '52000000-0000-0000-0000-000000000001', 'Service 14', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000015', 'aa000000-0000-0000-0000-000000000015', '52000000-0000-0000-0000-000000000001', 'Service 15', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000016', 'aa000000-0000-0000-0000-000000000016', '52000000-0000-0000-0000-000000000001', 'Service 16', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000017', 'aa000000-0000-0000-0000-000000000017', '52000000-0000-0000-0000-000000000001', 'Service 17', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000018', 'aa000000-0000-0000-0000-000000000018', '52000000-0000-0000-0000-000000000001', 'Service 18', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000019', 'aa000000-0000-0000-0000-000000000019', '52000000-0000-0000-0000-000000000001', 'Service 19', 'fixed', 150000, 'active'),
  ('bb000000-0000-0000-0000-000000000020', 'aa000000-0000-0000-0000-000000000020', '52000000-0000-0000-0000-000000000001', 'Service 20', 'fixed', 150000, 'active')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- BUSINESSES (20)
-- =============================================================================
INSERT INTO public.businesses (id, legal_name, display_name, tax_id, verification_status, billing_email, created_by, created_at, updated_at) VALUES
  ('cc000000-0000-0000-0000-000000000001', 'PT Bisnis 1', 'Bisnis 1', '01.000.000.0-000.001', 'verified', 'billing1@bisnis.com', '00000000-0000-0000-0000-000000000041', now(), now()),
  ('cc000000-0000-0000-0000-000000000002', 'PT Bisnis 2', 'Bisnis 2', '01.000.000.0-000.002', 'verified', 'billing2@bisnis.com', '00000000-0000-0000-0000-000000000042', now(), now()),
  ('cc000000-0000-0000-0000-000000000003', 'PT Bisnis 3', 'Bisnis 3', '01.000.000.0-000.003', 'verified', 'billing3@bisnis.com', '00000000-0000-0000-0000-000000000043', now(), now()),
  ('cc000000-0000-0000-0000-000000000004', 'PT Bisnis 4', 'Bisnis 4', '01.000.000.0-000.004', 'verified', 'billing4@bisnis.com', '00000000-0000-0000-0000-000000000044', now(), now()),
  ('cc000000-0000-0000-0000-000000000005', 'PT Bisnis 5', 'Bisnis 5', '01.000.000.0-000.005', 'verified', 'billing5@bisnis.com', '00000000-0000-0000-0000-000000000045', now(), now()),
  ('cc000000-0000-0000-0000-000000000006', 'PT Bisnis 6', 'Bisnis 6', '01.000.000.0-000.006', 'verified', 'billing6@bisnis.com', '00000000-0000-0000-0000-000000000046', now(), now()),
  ('cc000000-0000-0000-0000-000000000007', 'PT Bisnis 7', 'Bisnis 7', '01.000.000.0-000.007', 'verified', 'billing7@bisnis.com', '00000000-0000-0000-0000-000000000047', now(), now()),
  ('cc000000-0000-0000-0000-000000000008', 'PT Bisnis 8', 'Bisnis 8', '01.000.000.0-000.008', 'verified', 'billing8@bisnis.com', '00000000-0000-0000-0000-000000000048', now(), now()),
  ('cc000000-0000-0000-0000-000000000009', 'PT Bisnis 9', 'Bisnis 9', '01.000.000.0-000.009', 'verified', 'billing9@bisnis.com', '00000000-0000-0000-0000-000000000049', now(), now()),
  ('cc000000-0000-0000-0000-000000000010', 'PT Bisnis 10', 'Bisnis 10', '01.000.000.0-000.010', 'verified', 'billing10@bisnis.com', '00000000-0000-0000-0000-000000000050', now(), now()),
  ('cc000000-0000-0000-0000-000000000011', 'PT Bisnis 11', 'Bisnis 11', '01.000.000.0-000.011', 'verified', 'billing11@bisnis.com', '00000000-0000-0000-0000-000000000051', now(), now()),
  ('cc000000-0000-0000-0000-000000000012', 'PT Bisnis 12', 'Bisnis 12', '01.000.000.0-000.012', 'verified', 'billing12@bisnis.com', '00000000-0000-0000-0000-000000000052', now(), now()),
  ('cc000000-0000-0000-0000-000000000013', 'PT Bisnis 13', 'Bisnis 13', '01.000.000.0-000.013', 'verified', 'billing13@bisnis.com', '00000000-0000-0000-0000-000000000053', now(), now()),
  ('cc000000-0000-0000-0000-000000000014', 'PT Bisnis 14', 'Bisnis 14', '01.000.000.0-000.014', 'verified', 'billing14@bisnis.com', '00000000-0000-0000-0000-000000000054', now(), now()),
  ('cc000000-0000-0000-0000-000000000015', 'PT Bisnis 15', 'Bisnis 15', '01.000.000.0-000.015', 'verified', 'billing15@bisnis.com', '00000000-0000-0000-0000-000000000055', now(), now()),
  ('cc000000-0000-0000-0000-000000000016', 'PT Bisnis 16', 'Bisnis 16', '01.000.000.0-000.016', 'verified', 'billing16@bisnis.com', '00000000-0000-0000-0000-000000000056', now(), now()),
  ('cc000000-0000-0000-0000-000000000017', 'PT Bisnis 17', 'Bisnis 17', '01.000.000.0-000.017', 'verified', 'billing17@bisnis.com', '00000000-0000-0000-0000-000000000057', now(), now()),
  ('cc000000-0000-0000-0000-000000000018', 'PT Bisnis 18', 'Bisnis 18', '01.000.000.0-000.018', 'verified', 'billing18@bisnis.com', '00000000-0000-0000-0000-000000000058', now(), now()),
  ('cc000000-0000-0000-0000-000000000019', 'PT Bisnis 19', 'Bisnis 19', '01.000.000.0-000.019', 'verified', 'billing19@bisnis.com', '00000000-0000-0000-0000-000000000059', now(), now()),
  ('cc000000-0000-0000-0000-000000000020', 'PT Bisnis 20', 'Bisnis 20', '01.000.000.0-000.020', 'verified', 'billing20@bisnis.com', '00000000-0000-0000-0000-000000000060', now(), now())
ON CONFLICT DO NOTHING;

-- =============================================================================
-- BUSINESS MEMBERS (20)
-- =============================================================================
INSERT INTO public.business_members (business_id, user_id, role, status) VALUES
  ('cc000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000041', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000042', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000043', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000044', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000045', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000046', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000047', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000048', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000049', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000050', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000051', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000052', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000053', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000054', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000055', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000056', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000057', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000058', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000059', 'owner', 'active'),
  ('cc000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000060', 'owner', 'active')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- JOBS (20)
-- =============================================================================
INSERT INTO public.jobs (id, customer_id, service_id, title, description, booking_type, status) VALUES
  ('dd000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '52000000-0000-0000-0000-000000000001', 'Job Title 1', 'Description 1', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '52000000-0000-0000-0000-000000000001', 'Job Title 2', 'Description 2', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '52000000-0000-0000-0000-000000000001', 'Job Title 3', 'Description 3', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', '52000000-0000-0000-0000-000000000001', 'Job Title 4', 'Description 4', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', '52000000-0000-0000-0000-000000000001', 'Job Title 5', 'Description 5', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', '52000000-0000-0000-0000-000000000001', 'Job Title 6', 'Description 6', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007', '52000000-0000-0000-0000-000000000001', 'Job Title 7', 'Description 7', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000008', '52000000-0000-0000-0000-000000000001', 'Job Title 8', 'Description 8', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000009', '52000000-0000-0000-0000-000000000001', 'Job Title 9', 'Description 9', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000010', '52000000-0000-0000-0000-000000000001', 'Job Title 10', 'Description 10', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011', '52000000-0000-0000-0000-000000000001', 'Job Title 11', 'Description 11', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', '52000000-0000-0000-0000-000000000001', 'Job Title 12', 'Description 12', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000013', '52000000-0000-0000-0000-000000000001', 'Job Title 13', 'Description 13', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', '52000000-0000-0000-0000-000000000001', 'Job Title 14', 'Description 14', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000015', '52000000-0000-0000-0000-000000000001', 'Job Title 15', 'Description 15', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000016', '52000000-0000-0000-0000-000000000001', 'Job Title 16', 'Description 16', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000017', '52000000-0000-0000-0000-000000000001', 'Job Title 17', 'Description 17', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000018', '52000000-0000-0000-0000-000000000001', 'Job Title 18', 'Description 18', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000019', '52000000-0000-0000-0000-000000000001', 'Job Title 19', 'Description 19', 'scheduled', 'requested'),
  ('dd000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000020', '52000000-0000-0000-0000-000000000001', 'Job Title 20', 'Description 20', 'scheduled', 'requested')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- JOB MATCHES (20)
-- =============================================================================
INSERT INTO public.job_matches (job_id, provider_id, provider_service_id, rank, score, score_components, status, model_version) VALUES
  ('dd000000-0000-0000-0000-000000000001', 'aa000000-0000-0000-0000-000000000001', 'bb000000-0000-0000-0000-000000000001', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000002', 'aa000000-0000-0000-0000-000000000002', 'bb000000-0000-0000-0000-000000000002', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000003', 'aa000000-0000-0000-0000-000000000003', 'bb000000-0000-0000-0000-000000000003', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000004', 'aa000000-0000-0000-0000-000000000004', 'bb000000-0000-0000-0000-000000000004', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000005', 'aa000000-0000-0000-0000-000000000005', 'bb000000-0000-0000-0000-000000000005', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000006', 'aa000000-0000-0000-0000-000000000006', 'bb000000-0000-0000-0000-000000000006', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000007', 'aa000000-0000-0000-0000-000000000007', 'bb000000-0000-0000-0000-000000000007', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000008', 'aa000000-0000-0000-0000-000000000008', 'bb000000-0000-0000-0000-000000000008', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000009', 'aa000000-0000-0000-0000-000000000009', 'bb000000-0000-0000-0000-000000000009', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000010', 'aa000000-0000-0000-0000-000000000010', 'bb000000-0000-0000-0000-000000000010', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000011', 'aa000000-0000-0000-0000-000000000011', 'bb000000-0000-0000-0000-000000000011', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000012', 'aa000000-0000-0000-0000-000000000012', 'bb000000-0000-0000-0000-000000000012', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000013', 'aa000000-0000-0000-0000-000000000013', 'bb000000-0000-0000-0000-000000000013', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000014', 'aa000000-0000-0000-0000-000000000014', 'bb000000-0000-0000-0000-000000000014', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000015', 'aa000000-0000-0000-0000-000000000015', 'bb000000-0000-0000-0000-000000000015', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000016', 'aa000000-0000-0000-0000-000000000016', 'bb000000-0000-0000-0000-000000000016', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000017', 'aa000000-0000-0000-0000-000000000017', 'bb000000-0000-0000-0000-000000000017', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000018', 'aa000000-0000-0000-0000-000000000018', 'bb000000-0000-0000-0000-000000000018', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000019', 'aa000000-0000-0000-0000-000000000019', 'bb000000-0000-0000-0000-000000000019', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1'),
  ('dd000000-0000-0000-0000-000000000020', 'aa000000-0000-0000-0000-000000000020', 'bb000000-0000-0000-0000-000000000020', 1, 0.95, '{"relevance":0.95}'::jsonb, 'invited', 'deterministic-rules-v1')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- BOOKINGS (20)
-- =============================================================================
INSERT INTO public.bookings (id, job_id, customer_id, provider_id, provider_service_id, assigned_user_id, status, scheduled_start, scheduled_end, subtotal, platform_fee, tax_amount, total_amount, policy_snapshot) VALUES
  ('ee000000-0000-0000-0000-000000000001', 'dd000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'aa000000-0000-0000-0000-000000000001', 'bb000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000002', 'dd000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'aa000000-0000-0000-0000-000000000002', 'bb000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000022', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000003', 'dd000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'aa000000-0000-0000-0000-000000000003', 'bb000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000023', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000004', 'dd000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', 'aa000000-0000-0000-0000-000000000004', 'bb000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000024', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000005', 'dd000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', 'aa000000-0000-0000-0000-000000000005', 'bb000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000025', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000006', 'dd000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', 'aa000000-0000-0000-0000-000000000006', 'bb000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000026', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000007', 'dd000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007', 'aa000000-0000-0000-0000-000000000007', 'bb000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000027', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000008', 'dd000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000008', 'aa000000-0000-0000-0000-000000000008', 'bb000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000028', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000009', 'dd000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000009', 'aa000000-0000-0000-0000-000000000009', 'bb000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000029', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000010', 'dd000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000010', 'aa000000-0000-0000-0000-000000000010', 'bb000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000030', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000011', 'dd000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011', 'aa000000-0000-0000-0000-000000000011', 'bb000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000031', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000012', 'dd000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', 'aa000000-0000-0000-0000-000000000012', 'bb000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000032', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000013', 'dd000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000013', 'aa000000-0000-0000-0000-000000000013', 'bb000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000033', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000014', 'dd000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', 'aa000000-0000-0000-0000-000000000014', 'bb000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000034', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000015', 'dd000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000015', 'aa000000-0000-0000-0000-000000000015', 'bb000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000035', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000016', 'dd000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000016', 'aa000000-0000-0000-0000-000000000016', 'bb000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000036', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000017', 'dd000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000017', 'aa000000-0000-0000-0000-000000000017', 'bb000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000037', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000018', 'dd000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000018', 'aa000000-0000-0000-0000-000000000018', 'bb000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000038', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000019', 'dd000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000019', 'aa000000-0000-0000-0000-000000000019', 'bb000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000039', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb),
  ('ee000000-0000-0000-0000-000000000020', 'dd000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000020', 'aa000000-0000-0000-0000-000000000020', 'bb000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000040', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{"tax_pct":11}'::jsonb)
ON CONFLICT DO NOTHING;

