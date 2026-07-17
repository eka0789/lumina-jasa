import uuid

# Helpers
def gen_uuid(prefix, i):
    # e.g., '00000000-0000-0000-0000-000000000001'
    return f'{prefix}0000-0000-0000-0000-{str(i).zfill(12)}'

out = []
out.append('-- =============================================================================')
out.append('-- LUMINA JASA - SEED DATA (20 entries per table)')
out.append('-- =============================================================================')
out.append("SELECT set_config('app.environment', 'development', false);")

# 1. AUTH USERS (60 users: 1-20 customers, 21-40 provider owners, 41-60 business owners/staff)
out.append('-- =============================================================================')
out.append('-- AUTH USERS')
out.append('-- =============================================================================')
out.append('INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token) VALUES')

users = []
for i in range(1, 61):
    u_id = gen_uuid('0000', i)
    email = f'user{i}@example.com'
    name = f'User {i}'
    users.append(f"  ('{u_id}','00000000-0000-0000-0000-000000000000','authenticated','authenticated','{email}', crypt('password123',gen_salt('bf')), now(),now(),now(),'{{\"provider\":\"email\",\"providers\":[\"email\"]}}','{{\"full_name\":\"{name}\"}}', now(),now(),'','','','')")

out.append(',\n'.join(users))
out.append('ON CONFLICT (id) DO NOTHING;\n')

# 2. AUTH IDENTITIES
out.append('-- =============================================================================')
out.append('-- AUTH IDENTITIES')
out.append('-- =============================================================================')
out.append('INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)')
out.append("SELECT gen_random_uuid(), id::text, id, format('{\"sub\":\"%s\",\"email\":\"%s\"}', id, email)::jsonb, 'email', now(), now(), now() FROM auth.users ON CONFLICT DO NOTHING;\n")

# 3. USER ROLES
out.append('-- =============================================================================')
out.append('-- USER ROLES (20 roles)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.user_roles (user_id, role) VALUES')
roles = []
for i in range(1, 19):
    u_id = gen_uuid('0000', i)
    roles.append(f"  ('{u_id}', 'customer')")
roles.append(f"  ('{gen_uuid('0000', 19)}', 'admin')")
roles.append(f"  ('{gen_uuid('0000', 20)}', 'super_admin')")
out.append(',\n'.join(roles))
out.append('ON CONFLICT DO NOTHING;\n')

# 4. PROVIDERS (20 providers)
out.append('-- =============================================================================')
out.append('-- PROVIDERS (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.providers (id, owner_user_id, display_name, slug, bio, status, verification_status, rating_avg, rating_count, completed_jobs, response_rate, created_at, updated_at) VALUES')
providers = []
for i in range(1, 21):
    p_id = gen_uuid('aa00', i)
    u_id = gen_uuid('0000', 20 + i) # Users 21-40
    providers.append(f"  ('{p_id}', '{u_id}', 'Provider {i}', 'provider-{i}', 'Bio provider {i}', 'active', 'verified', 4.5, 10, 50, 95.0, now(), now())")
out.append(',\n'.join(providers))
out.append('ON CONFLICT DO NOTHING;\n')

# 5. PROVIDER MEMBERS
out.append('-- =============================================================================')
out.append('-- PROVIDER MEMBERS (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.provider_members (provider_id, user_id, role, status) VALUES')
members = []
for i in range(1, 21):
    p_id = gen_uuid('aa00', i)
    u_id = gen_uuid('0000', 20 + i)
    members.append(f"  ('{p_id}', '{u_id}', 'owner', 'active')")
out.append(',\n'.join(members))
out.append('ON CONFLICT DO NOTHING;\n')

# 6. PROVIDER SERVICES (20)
out.append('-- =============================================================================')
out.append('-- PROVIDER SERVICES (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.provider_services (id, provider_id, service_id, title, pricing_type, base_price, status) VALUES')
pservices = []
for i in range(1, 21):
    ps_id = gen_uuid('bb00', i)
    p_id = gen_uuid('aa00', i)
    s_id = '52000000-0000-0000-0000-000000000001' # Needs to reference existing or just use a dummy one
    pservices.append(f"  ('{ps_id}', '{p_id}', '{s_id}', 'Service {i}', 'fixed', 150000, 'active')")
out.append(',\n'.join(pservices))
out.append('ON CONFLICT DO NOTHING;\n')

# 7. BUSINESSES (20)
out.append('-- =============================================================================')
out.append('-- BUSINESSES (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.businesses (id, legal_name, display_name, tax_id, verification_status, billing_email, created_by, created_at, updated_at) VALUES')
businesses = []
for i in range(1, 21):
    b_id = gen_uuid('cc00', i)
    u_id = gen_uuid('0000', 40 + i) # Users 41-60
    businesses.append(f"  ('{b_id}', 'PT Bisnis {i}', 'Bisnis {i}', '01.000.000.0-000.0{str(i).zfill(2)}', 'verified', 'billing{i}@bisnis.com', '{u_id}', now(), now())")
out.append(',\n'.join(businesses))
out.append('ON CONFLICT DO NOTHING;\n')

# 8. BUSINESS MEMBERS (20)
out.append('-- =============================================================================')
out.append('-- BUSINESS MEMBERS (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.business_members (business_id, user_id, role, status) VALUES')
bmembers = []
for i in range(1, 21):
    b_id = gen_uuid('cc00', i)
    u_id = gen_uuid('0000', 40 + i)
    bmembers.append(f"  ('{b_id}', '{u_id}', 'owner', 'active')")
out.append(',\n'.join(bmembers))
out.append('ON CONFLICT DO NOTHING;\n')

# 9. JOBS (20)
out.append('-- =============================================================================')
out.append('-- JOBS (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.jobs (id, customer_id, service_id, title, description, booking_type, status) VALUES')
jobs = []
for i in range(1, 21):
    j_id = gen_uuid('dd00', i)
    c_id = gen_uuid('0000', i) # Users 1-20
    s_id = '52000000-0000-0000-0000-000000000001'
    jobs.append(f"  ('{j_id}', '{c_id}', '{s_id}', 'Job Title {i}', 'Description {i}', 'scheduled', 'requested')")
out.append(',\n'.join(jobs))
out.append('ON CONFLICT DO NOTHING;\n')

# 10. JOB MATCHES (20)
out.append('-- =============================================================================')
out.append('-- JOB MATCHES (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.job_matches (job_id, provider_id, provider_service_id, rank, score, score_components, status, model_version) VALUES')
matches = []
for i in range(1, 21):
    j_id = gen_uuid('dd00', i)
    p_id = gen_uuid('aa00', i)
    ps_id = gen_uuid('bb00', i)
    matches.append(f"  ('{j_id}', '{p_id}', '{ps_id}', 1, 0.95, '{{\"relevance\":0.95}}'::jsonb, 'invited', 'deterministic-rules-v1')")
out.append(',\n'.join(matches))
out.append('ON CONFLICT DO NOTHING;\n')

# 11. BOOKINGS (20)
out.append('-- =============================================================================')
out.append('-- BOOKINGS (20)')
out.append('-- =============================================================================')
out.append('INSERT INTO public.bookings (id, job_id, customer_id, provider_id, provider_service_id, assigned_user_id, status, scheduled_start, scheduled_end, subtotal, platform_fee, tax_amount, total_amount, policy_snapshot) VALUES')
bookings = []
for i in range(1, 21):
    bk_id = gen_uuid('ee00', i)
    j_id = gen_uuid('dd00', i)
    c_id = gen_uuid('0000', i)
    p_id = gen_uuid('aa00', i)
    ps_id = gen_uuid('bb00', i)
    u_id = gen_uuid('0000', 20 + i) # Provider owner assigned
    bookings.append(f"  ('{bk_id}', '{j_id}', '{c_id}', '{p_id}', '{ps_id}', '{u_id}', 'awaiting_payment', now() + interval '1 day', now() + interval '1 day 2 hours', 150000, 7500, 15750, 173250, '{{\"tax_pct\":11}}'::jsonb)")
out.append(',\n'.join(bookings))
out.append('ON CONFLICT DO NOTHING;\n')

with open('supabase/seed.sql', 'w') as f:
    f.write('\n'.join(out) + '\n')
print("seed.sql generated successfully.")
