-- Lumina Jasa - connected demo data for Supabase SQL Editor
-- Run AFTER 01_all_migrations.sql, and only in a development/staging project.
-- All demo accounts use the password: Demo12345!

begin;

-- ---------------------------------------------------------------------------
-- Demo identities. The auth trigger creates public.profiles and customer roles.
-- ---------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000001','authenticated','authenticated','customer@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Citra Pelanggan"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000002','authenticated','authenticated','provider@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Budi Teknisi"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000003','authenticated','authenticated','support@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Sari Support"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000004','authenticated','authenticated','finance@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Fina Finance"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000005','authenticated','authenticated','compliance@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Karin Compliance"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000006','authenticated','authenticated','admin@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Andi Admin"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000007','authenticated','authenticated','requester@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Raka Requester"}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','d0000000-0000-0000-0000-000000000008','authenticated','authenticated','approver@demo.luminajasa.id',crypt('Demo12345!',gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{"full_name":"Ayu Approver"}',now(),now())
on conflict (id) do update set
  encrypted_password=excluded.encrypted_password,
  email_confirmed_at=excluded.email_confirmed_at,
  raw_app_meta_data=excluded.raw_app_meta_data,
  raw_user_meta_data=excluded.raw_user_meta_data,
  updated_at=now();

insert into auth.identities (id,user_id,identity_data,provider,provider_id,last_sign_in_at,created_at,updated_at)
select gen_random_uuid(),u.id,jsonb_build_object('sub',u.id::text,'email',u.email),'email',u.email,now(),now(),now()
from auth.users u
where u.id between 'd0000000-0000-0000-0000-000000000001'::uuid and 'd0000000-0000-0000-0000-000000000008'::uuid
on conflict (provider_id,provider) do update set identity_data=excluded.identity_data,updated_at=now();

insert into public.user_roles(user_id,role) values
  ('d0000000-0000-0000-0000-000000000003','support'),
  ('d0000000-0000-0000-0000-000000000004','finance'),
  ('d0000000-0000-0000-0000-000000000005','compliance'),
  ('d0000000-0000-0000-0000-000000000006','admin')
on conflict (user_id,role) do update set revoked_at=null;

insert into public.addresses(id,user_id,label,recipient_name,phone,address_line1,district,city,province,postal_code,is_default) values
  ('d0100000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','Rumah','Citra Pelanggan','081234567890','Jl. Melati No. 10','Kebayoran Baru','Jakarta Selatan','DKI Jakarta','12120',true),
  ('d0100000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000007','Kantor','Raka Requester','081298765432','Jl. Jenderal Sudirman Kav. 20','Setiabudi','Jakarta Selatan','DKI Jakarta','12910',true)
on conflict (id) do update set address_line1=excluded.address_line1,updated_at=now();

-- ---------------------------------------------------------------------------
-- One verified catalog provider and one provider awaiting KYC review.
-- ---------------------------------------------------------------------------
insert into public.providers(id,owner_user_id,display_name,slug,bio,status,verification_status,rating_avg,rating_count,completed_jobs,response_rate,service_radius_km,service_area_labels) values
  ('d1000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002','Budi Teknik Demo','budi-teknik-demo','Teknisi AC, listrik ringan, dan perawatan rumah untuk area Jabodetabek.','active','verified',4.90,128,342,96,20,array['Jakarta Selatan','Depok','Tangerang Selatan']),
  ('d1000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','Budi Renovasi Baru','budi-renovasi-pending','Profil demo yang sedang menunggu pemeriksaan dokumen.','pending_verification','pending',0,0,0,0,15,array['Jakarta Selatan'])
on conflict (id) do update set display_name=excluded.display_name,bio=excluded.bio,status=excluded.status,verification_status=excluded.verification_status,service_area_labels=excluded.service_area_labels,updated_at=now();

insert into public.provider_members(provider_id,user_id,role,status) values
  ('d1000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002','owner','active'),
  ('d1000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','owner','active')
on conflict (provider_id,user_id) do update set role=excluded.role,status=excluded.status;

insert into public.provider_services(id,provider_id,service_id,title,description,pricing_type,base_price,min_duration_minutes,instant_bookable,status) values
  ('d2000000-0000-0000-0000-000000000001','d1000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001','Servis dan Cuci AC','Pemeriksaan, pembersihan, dan perbaikan ringan AC.','from',250000,90,true,'active'),
  ('d2000000-0000-0000-0000-000000000002','d1000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000002','Perbaikan Listrik Rumah','Diagnosis dan perbaikan gangguan listrik ringan.','from',300000,120,false,'active'),
  ('d2000000-0000-0000-0000-000000000003','d1000000-0000-0000-0000-000000000002','52000000-0000-0000-0000-000000000005','Renovasi Ruang Demo','Estimasi renovasi sesuai survei lokasi.','quote',null,null,false,'draft')
on conflict (id) do update set title=excluded.title,base_price=excluded.base_price,status=excluded.status,updated_at=now();

insert into public.provider_availability(id,provider_id,weekday,starts_at,ends_at,capacity)
select ('d3000000-0000-0000-0000-00000000000'||(day+1))::uuid,'d1000000-0000-0000-0000-000000000001',day,'00:00','23:59',2
from generate_series(0,6) day
on conflict (id) do update set starts_at=excluded.starts_at,ends_at=excluded.ends_at,capacity=excluded.capacity;

insert into public.files(id,owner_user_id,bucket,object_path,original_name,mime_type,size_bytes,sha256,scan_status,classification) values
  ('d4000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002','compliance-documents','d1000000/provider-identity-demo.pdf','provider-identity-demo.pdf','application/pdf',245760,'demo-sha256-not-a-real-document','clean','restricted')
on conflict (id) do update set scan_status=excluded.scan_status;

insert into public.verification_cases(id,subject_user_id,provider_id,kind,vendor,status,risk_score,submitted_at) values
  ('d4100000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000002','d1000000-0000-0000-0000-000000000002','kyc','demo-manual','manual_review',15,now()-interval '2 days')
on conflict (id) do update set status=excluded.status,risk_score=excluded.risk_score;

insert into public.compliance_documents(id,verification_case_id,file_id,document_type,country_code,extracted_data,status) values
  ('d4200000-0000-0000-0000-000000000001','d4100000-0000-0000-0000-000000000001','d4000000-0000-0000-0000-000000000001','identity_card','ID','{"demo":true,"name":"Budi Teknisi"}','pending')
on conflict (id) do update set status=excluded.status;

-- ---------------------------------------------------------------------------
-- Exercise the same authenticated functions used by the application.
-- ---------------------------------------------------------------------------
create temporary table if not exists demo_ids(kind text primary key,id uuid) on commit drop;
grant select,insert,update on table demo_ids to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
insert into demo_ids values ('job',public.submit_job_request(
  '52000000-0000-0000-0000-000000000001','AC kamar tidak dingin',
  'AC kamar utama tidak dingin sejak kemarin dan perlu diperiksa oleh teknisi.',
  date_trunc('day',now()+interval '3 days')+interval '8 hours',
  date_trunc('day',now()+interval '3 days')+interval '18 hours',150000,500000,'demo-customer-job-v1'
)) on conflict (kind) do update set id=excluded.id;

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal1"}',true);
insert into demo_ids values ('quote',public.submit_job_quote(
  (select id from demo_ids where kind='job'),'d2000000-0000-0000-0000-000000000001',
  325000,120,'Termasuk pemeriksaan, cuci AC, dan perbaikan ringan.',now()+interval '2 days'
)) on conflict (kind) do update set id=excluded.id;

select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
insert into demo_ids values ('booking',public.accept_quote_and_create_booking(
  (select id from demo_ids where kind='quote'),date_trunc('day',now()+interval '3 days')+interval '10 hours','demo-customer-booking-v1'
)) on conflict (kind) do update set id=excluded.id;

insert into demo_ids
select 'safe_message',public.send_moderated_message(c.id,gen_random_uuid(),'Halo Pak Budi, alamat dan jadwal sudah sesuai.')
from public.conversations c where c.booking_id=(select id from demo_ids where kind='booking')
on conflict (kind) do update set id=excluded.id;

insert into demo_ids
select 'flagged_message',public.send_moderated_message(c.id,gen_random_uuid(),'Tolong kirim nomor kartu dan kata sandi untuk pembayaran.')
from public.conversations c where c.booking_id=(select id from demo_ids where kind='booking')
on conflict (kind) do update set id=excluded.id;

insert into demo_ids values ('privacy',public.submit_privacy_request(
  'export','Mohon ekspor data akun demo saya.','demo-privacy-v1'
)) on conflict (kind) do update set id=excluded.id;

-- Business requester, approver, approval rule, and a pending approval request.
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000007',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000007","role":"authenticated","aal":"aal1"}',true);
insert into demo_ids values ('business',public.create_business(
  'PT Lumina Demo Indonesia','Lumina Demo Bisnis','billing@demo.luminajasa.id','demo-business-v1'
)) on conflict (kind) do update set id=excluded.id;
select public.add_business_member((select id from demo_ids where kind='business'),'approver@demo.luminajasa.id','approver',0,'demo-business-approver-v1');
insert into demo_ids values ('approval_rule',public.create_business_approval_rule(
  (select id from demo_ids where kind='business'),'Belanja di atas Rp100.000',100000,1,'demo-business-rule-v1'
)) on conflict (kind) do update set id=excluded.id;
insert into demo_ids values ('business_job',public.submit_job_request(
  '52000000-0000-0000-0000-000000000002','Perbaikan listrik kantor',
  'Lampu dan beberapa stop kontak di ruang rapat tidak berfungsi.',
  date_trunc('day',now()+interval '5 days')+interval '8 hours',
  date_trunc('day',now()+interval '5 days')+interval '18 hours',250000,750000,'demo-business-job-v1'
)) on conflict (kind) do update set id=excluded.id;
insert into demo_ids values ('approval_request',public.request_business_job_approval(
  (select id from demo_ids where kind='business'),(select id from demo_ids where kind='business_job'),450000,'demo-approval-request-v1'
)) on conflict (kind) do update set id=excluded.id;

-- Emergency dispatch and durable provider notification.
update public.services set emergency_enabled=true where id='52000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
insert into demo_ids values ('emergency_job',public.submit_emergency_job_request(
  '52000000-0000-0000-0000-000000000001','AC mengeluarkan asap',
  'Unit AC mengeluarkan asap tipis, listrik sudah dimatikan dan area diamankan.',750000,true,'demo-emergency-v1'
)) on conflict (kind) do update set id=excluded.id;

-- Human-review fraud case for scale operations.
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000003',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}',true);
insert into demo_ids values ('fraud_signal',public.record_manual_fraud_signal(
  'd0000000-0000-0000-0000-000000000001',null,'velocity',0.72,
  'Lonjakan permintaan demo perlu ditinjau manusia.','demo-fraud-signal-v1'
)) on conflict (kind) do update set id=excluded.id;
insert into demo_ids values ('fraud_case',public.open_fraud_case(
  'd0000000-0000-0000-0000-000000000001',null,
  'Sinyal velocity melewati ambang review manual.','demo-fraud-case-v1'
)) on conflict (kind) do update set id=excluded.id;

-- Historical forecast visible in the scale dashboard.
select set_config('request.jwt.claim.sub','d0000000-0000-0000-0000-000000000006',true);
select set_config('request.jwt.claims','{"sub":"d0000000-0000-0000-0000-000000000006","role":"authenticated","aal":"aal2"}',true);
insert into demo_ids values ('forecast',public.refresh_demand_forecast(
  '52000000-0000-0000-0000-000000000001','ID-JK','demo-forecast-v1'
)) on conflict (kind) do update set id=excluded.id;

reset role;
commit;

-- Demo logins:
-- customer@demo.luminajasa.id   / Demo12345!
-- provider@demo.luminajasa.id   / Demo12345!
-- support@demo.luminajasa.id    / Demo12345!
-- finance@demo.luminajasa.id    / Demo12345!
-- compliance@demo.luminajasa.id / Demo12345!
-- admin@demo.luminajasa.id      / Demo12345!
-- requester@demo.luminajasa.id  / Demo12345!
-- approver@demo.luminajasa.id   / Demo12345!
