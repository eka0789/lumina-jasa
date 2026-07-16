begin;

create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists postgis;
create extension if not exists vector;

create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email citext, phone text, full_name text not null, avatar_url text,
  locale text not null default 'id-ID', time_zone text not null default 'Asia/Jakarta',
  status text not null default 'active' check (status in ('active','suspended','deleted')),
  trust_score numeric(5,2) not null default 50 check (trust_score between 0 and 100),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,email,phone,full_name)
  values (
    new.id,
    new.email,
    new.phone,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name',''), nullif(split_part(coalesce(new.email,''),'@',1),''), 'Pengguna Lumina')
  );
  insert into public.user_roles(user_id,role) values (new.id,'customer') on conflict do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('customer','support','finance','compliance','ai_moderator','admin','super_admin')),
  granted_by uuid references public.profiles(id), granted_at timestamptz not null default now(), revoked_at timestamptz,
  primary key (user_id, role)
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete cascade,
  label text, recipient_name text, phone text, address_line1 text not null, address_line2 text,
  district text, city text not null, province text not null, postal_code text, country_code char(2) not null default 'ID',
  location geography(point,4326), is_default boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.businesses (
  id uuid primary key default gen_random_uuid(), legal_name text not null, display_name text not null,
  tax_id text, registration_number text, verification_status text not null default 'unverified'
    check (verification_status in ('unverified','pending','verified','rejected','suspended')),
  billing_email citext, time_zone text not null default 'Asia/Jakarta', version integer not null default 1,
  created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.business_members (
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('owner','admin','requester','approver','viewer')),
  status text not null default 'active' check (status in ('invited','active','suspended','removed')),
  spend_limit bigint check (spend_limit is null or spend_limit >= 0), joined_at timestamptz not null default now(),
  primary key (business_id,user_id)
);

create table public.providers (
  id uuid primary key default gen_random_uuid(), owner_user_id uuid not null references public.profiles(id),
  business_id uuid references public.businesses(id), display_name text not null, slug citext not null unique,
  bio text, status text not null default 'draft' check (status in ('draft','pending_verification','active','paused','suspended','rejected')),
  verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified','rejected','expired')),
  rating_avg numeric(3,2) not null default 0 check (rating_avg between 0 and 5), rating_count integer not null default 0 check (rating_count >= 0),
  completed_jobs integer not null default 0 check (completed_jobs >= 0), response_rate numeric(5,2) not null default 0 check (response_rate between 0 and 100),
  base_location geography(point,4326), service_radius_km numeric(8,2), version integer not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.provider_members (
  provider_id uuid not null references public.providers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('owner','manager','worker')), status text not null default 'active' check (status in ('invited','active','suspended','removed')),
  created_at timestamptz not null default now(), primary key (provider_id,user_id)
);

create table public.categories (
  id uuid primary key default gen_random_uuid(), parent_id uuid references public.categories(id),
  name text not null, slug citext not null unique, description text, sort_order integer not null default 0,
  status text not null default 'active' check (status in ('draft','active','archived')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (id <> parent_id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(), category_id uuid not null references public.categories(id),
  name text not null, slug citext not null unique, description text, default_duration_minutes integer check (default_duration_minutes > 0),
  emergency_enabled boolean not null default false, status text not null default 'active' check (status in ('draft','active','archived')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.provider_services (
  id uuid primary key default gen_random_uuid(), provider_id uuid not null references public.providers(id) on delete cascade,
  service_id uuid not null references public.services(id), title text not null, description text,
  pricing_type text not null check (pricing_type in ('fixed','hourly','from','quote')),
  base_price bigint check (base_price is null or base_price >= 0), currency char(3) not null default 'IDR',
  min_duration_minutes integer check (min_duration_minutes is null or min_duration_minutes > 0),
  instant_bookable boolean not null default false, status text not null default 'draft' check (status in ('draft','active','paused','rejected')),
  embedding vector(1536), version integer not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(provider_id,service_id,title)
);

create table public.provider_availability (
  id uuid primary key default gen_random_uuid(), provider_id uuid not null references public.providers(id) on delete cascade,
  weekday smallint check (weekday between 0 and 6), starts_at time, ends_at time,
  specific_date date, is_available boolean not null default true, capacity smallint not null default 1 check (capacity > 0),
  created_at timestamptz not null default now(),
  check ((weekday is not null and specific_date is null) or (weekday is null and specific_date is not null)),
  check (starts_at is null or ends_at is null or starts_at < ends_at)
);

create table public.provider_service_areas (
  id uuid primary key default gen_random_uuid(), provider_id uuid not null references public.providers(id) on delete cascade,
  name text not null, area geography(multipolygon,4326) not null, created_at timestamptz not null default now()
);

create table public.files (
  id uuid primary key default gen_random_uuid(), owner_user_id uuid references public.profiles(id), business_id uuid references public.businesses(id),
  bucket text not null, object_path text not null, original_name text, mime_type text not null, size_bytes bigint not null check (size_bytes >= 0),
  sha256 text, scan_status text not null default 'pending' check (scan_status in ('pending','clean','infected','failed')),
  classification text not null default 'private' check (classification in ('public','private','sensitive','restricted')),
  created_at timestamptz not null default now(), deleted_at timestamptz, unique(bucket,object_path)
);

create table public.provider_portfolios (
  id uuid primary key default gen_random_uuid(), provider_id uuid not null references public.providers(id) on delete cascade,
  title text not null, description text, file_id uuid references public.files(id), sort_order integer not null default 0,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id),
  business_id uuid references public.businesses(id), service_id uuid references public.services(id), address_id uuid references public.addresses(id),
  title text not null, description text not null, booking_type text not null default 'scheduled' check (booking_type in ('instant','scheduled','emergency')),
  status text not null default 'draft' check (status in ('draft','requested','matched','awaiting_payment','confirmed','accepted','en_route','in_progress','provider_completed','customer_confirmed','disputed','resolved','closed','cancelled')),
  requested_start timestamptz, requested_end timestamptz, location geography(point,4326),
  budget_min bigint check (budget_min is null or budget_min >= 0), budget_max bigint check (budget_max is null or budget_max >= budget_min),
  currency char(3) not null default 'IDR', ai_intake jsonb not null default '{}'::jsonb, version integer not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.job_media (
  job_id uuid not null references public.jobs(id) on delete cascade, file_id uuid not null references public.files(id) on delete restrict,
  purpose text not null check (purpose in ('request','progress','completion','dispute')), created_at timestamptz not null default now(),
  primary key(job_id,file_id)
);

create table public.job_matches (
  id uuid primary key default gen_random_uuid(), job_id uuid not null references public.jobs(id) on delete cascade,
  provider_id uuid not null references public.providers(id), provider_service_id uuid references public.provider_services(id),
  rank integer not null check (rank > 0), score numeric(8,5) not null, score_components jsonb not null, reason_codes text[] not null default '{}',
  model_version text not null, status text not null default 'recommended' check (status in ('recommended','viewed','invited','accepted','declined','expired')),
  created_at timestamptz not null default now(), unique(job_id,provider_id)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(), job_id uuid not null unique references public.jobs(id),
  customer_id uuid not null references public.profiles(id), business_id uuid references public.businesses(id), provider_id uuid not null references public.providers(id),
  provider_service_id uuid references public.provider_services(id), assigned_user_id uuid references public.profiles(id),
  status text not null default 'awaiting_payment' check (status in ('awaiting_payment','confirmed','accepted','en_route','in_progress','provider_completed','customer_confirmed','disputed','resolved','closed','cancelled')),
  scheduled_start timestamptz not null, scheduled_end timestamptz, subtotal bigint not null check (subtotal >= 0),
  platform_fee bigint not null default 0 check (platform_fee >= 0), tax_amount bigint not null default 0 check (tax_amount >= 0),
  total_amount bigint not null check (total_amount >= 0), currency char(3) not null default 'IDR', policy_snapshot jsonb not null,
  version integer not null default 1, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (total_amount = subtotal + platform_fee + tax_amount)
);

create table public.job_status_events (
  id bigint generated always as identity primary key, booking_id uuid not null references public.bookings(id),
  from_status text, to_status text not null, actor_user_id uuid references public.profiles(id), reason_code text, note text, evidence jsonb,
  created_at timestamptz not null default now()
);

create table public.tracking_points (
  id bigint generated always as identity primary key, booking_id uuid not null references public.bookings(id) on delete cascade,
  provider_user_id uuid not null references public.profiles(id), location geography(point,4326) not null,
  accuracy_meters numeric(8,2), heading numeric(6,2), speed_mps numeric(8,2), captured_at timestamptz not null,
  received_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(), booking_id uuid unique references public.bookings(id),
  kind text not null default 'job' check (kind in ('job','support','dispute')), created_at timestamptz not null default now(), closed_at timestamptz
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, participant_role text not null,
  joined_at timestamptz not null default now(), left_at timestamptz, primary key(conversation_id,user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id), client_id uuid not null, kind text not null default 'text' check (kind in ('text','system','image','file','voice')),
  body text, reply_to_id uuid references public.messages(id), moderation_status text not null default 'unchecked' check (moderation_status in ('unchecked','allowed','flagged','blocked')),
  created_at timestamptz not null default now(), edited_at timestamptz, deleted_at timestamptz,
  unique(conversation_id,sender_user_id,client_id), check (body is not null or kind in ('image','file','voice'))
);

create table public.message_attachments (
  message_id uuid not null references public.messages(id) on delete cascade, file_id uuid not null references public.files(id),
  primary key(message_id,file_id)
);

create table public.message_receipts (
  message_id uuid not null references public.messages(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
  delivered_at timestamptz, read_at timestamptz, primary key(message_id,user_id)
);

commit;
