-- Local/test-only switches. Production remains fail-closed when this setting is absent.
SELECT set_config('app.environment', 'development', false);

-- Insert dummy users into auth.users
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, 
  recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, 
  created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
)
VALUES 
  (
    '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 
    'authenticated', 'authenticated', 'customer@example.com', crypt('password123', gen_salt('bf')), 
    now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dummy Customer"}', 
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 
    'authenticated', 'authenticated', 'provider@example.com', crypt('password123', gen_salt('bf')), 
    now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dummy Provider"}', 
    now(), now(), '', '', '', ''
  );

-- Insert dummy identities
INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
VALUES
  (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', format('{"sub":"%s","email":"%s"}', '00000000-0000-0000-0000-000000000001', 'customer@example.com')::jsonb, 'email', now(), now(), now()),
  (gen_random_uuid(), '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', format('{"sub":"%s","email":"%s"}', '00000000-0000-0000-0000-000000000002', 'provider@example.com')::jsonb, 'email', now(), now(), now());

-- Give roles
INSERT INTO public.user_roles (user_id, role)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'customer'),
  ('00000000-0000-0000-0000-000000000002', 'customer') -- providers also have customer role initially
ON CONFLICT DO NOTHING;

-- Dummy Provider Profile
INSERT INTO public.providers (id, owner_user_id, display_name, slug, bio, status, verification_status, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000002',
  'Dummy AC Services',
  'dummy-ac-services',
  'We provide the best AC repair services in town.',
  'active',
  'verified',
  now(),
  now()
);

-- Provider Members
INSERT INTO public.provider_members (provider_id, user_id, role, status)
VALUES (
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000002',
  'owner',
  'active'
);

-- Dummy Provider Service (using the service 'Servis AC' from catalog seed which has id '52000000-0000-0000-0000-000000000001')
INSERT INTO public.provider_services (id, provider_id, service_id, title, pricing_type, base_price, status)
VALUES (
  '00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000003',
  '52000000-0000-0000-0000-000000000001',
  'Premium AC Service',
  'fixed',
  150000,
  'active'
);

-- Dummy Job Request (from customer)
INSERT INTO public.jobs (id, customer_id, service_id, title, description, booking_type, status)
VALUES (
  '00000000-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000001',
  '52000000-0000-0000-0000-000000000001',
  'AC is not cooling',
  'My AC is blowing warm air, needs inspection and freon refill.',
  'scheduled',
  'requested'
);

-- Dummy Job Match (link job to provider so it appears in Provider Dashboard)
INSERT INTO public.job_matches (job_id, provider_id, provider_service_id, rank, score, score_components, status, model_version)
VALUES (
  '00000000-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000004',
  1,
  0.95,
  '{"distance":0.9,"rating":1.0,"availability":0.95}'::jsonb,
  'invited',
  'v1.0.0'
);
