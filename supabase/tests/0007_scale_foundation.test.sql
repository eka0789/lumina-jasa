begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users(id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,aud,role) values
('a0000000-0000-0000-0000-000000000001','scale-customer@example.test','',now(),'{}','{"full_name":"Scale Customer"}','authenticated','authenticated'),
('a0000000-0000-0000-0000-000000000002','scale-provider@example.test','',now(),'{}','{"full_name":"Scale Provider"}','authenticated','authenticated'),
('a0000000-0000-0000-0000-000000000003','scale-support@example.test','',now(),'{}','{"full_name":"Scale Support"}','authenticated','authenticated'),
('a0000000-0000-0000-0000-000000000004','scale-compliance@example.test','',now(),'{}','{"full_name":"Scale Compliance"}','authenticated','authenticated'),
('a0000000-0000-0000-0000-000000000005','scale-admin@example.test','',now(),'{}','{"full_name":"Scale Admin"}','authenticated','authenticated');
insert into public.user_roles(user_id,role) values('a0000000-0000-0000-0000-000000000003','support'),('a0000000-0000-0000-0000-000000000004','compliance'),('a0000000-0000-0000-0000-000000000005','admin');
update public.services set emergency_enabled=true where id='52000000-0000-0000-0000-000000000001';
insert into public.providers(id,owner_user_id,display_name,slug,status,verification_status,response_rate,rating_avg) values('a1000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','Scale Teknik','scale-teknik','active','verified',98,4.8);
insert into public.provider_members(provider_id,user_id,role,status) values('a1000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','owner','active');
insert into public.provider_services(id,provider_id,service_id,title,pricing_type,base_price,status) values('a2000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001','Emergency Scale Service','from',300000,'active');
create temporary table scale_ids(kind text primary key,id uuid);

set local role authenticated;
select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.submit_emergency_job_request('52000000-0000-0000-0000-000000000001','Pipa bocor','Kebocoran besar perlu ditangani segera di dapur.',500000,false,'emergency-unsafe')$$,'22023','emergency request incomplete','emergency request requires safety confirmation');
select lives_ok($$insert into scale_ids values('emergency_job',public.submit_emergency_job_request('52000000-0000-0000-0000-000000000001','Pipa bocor','Kebocoran besar perlu ditangani segera di dapur.',500000,true,'emergency-safe'))$$,'eligible customer submits emergency dispatch');
select is((select booking_type from public.jobs where id=(select id from scale_ids where kind='emergency_job')),'emergency','job records emergency mode');
select ok((select count(*) between 1 and 5 from public.job_matches where job_id=(select id from scale_ids where kind='emergency_job')),'dispatch invites a bounded provider set');
select ok(exists(select 1 from public.notifications where user_id='a0000000-0000-0000-0000-000000000002' and event_type='emergency.job_invited' and channel='in_app'),'provider receives durable in-app emergency notification');

select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.record_manual_fraud_signal('a0000000-0000-0000-0000-000000000001',null,'velocity',0.75,'Velocity membutuhkan pemeriksaan.','fraud-aal1')$$,'42501','fraud reviewer AAL2 required','fraud signal requires AAL2');
select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$insert into scale_ids values('signal',public.record_manual_fraud_signal('a0000000-0000-0000-0000-000000000001',null,'velocity',0.75,'Velocity membutuhkan pemeriksaan.','fraud-signal'))$$,'support records explainable signal');
select lives_ok($$insert into scale_ids values('fraud_case',public.open_fraud_case('a0000000-0000-0000-0000-000000000001',null,'Sinyal aktif melewati ambang pemeriksaan.','fraud-case'))$$,'support opens human-review fraud case');
select is((select count(*) from public.blacklist_entries where subject_hash='a0000000-0000-0000-0000-000000000001'),0::bigint,'case opening never auto-blacklists user');
select throws_ok($$select public.decide_fraud_case((select id from scale_ids where kind='fraud_case'),'confirmed','Support mencoba keputusan akhir.','fraud-support-decision')$$,'42501','fraud decision AAL2 required','support cannot make final fraud decision');
select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000004',true);select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000004","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.decide_fraud_case((select id from scale_ids where kind='fraud_case'),'confirmed','Evidence manual telah diverifikasi.','fraud-confirm')$$,'compliance records reasoned fraud outcome');
select is((select status from public.fraud_cases where id=(select id from scale_ids where kind='fraud_case')),'confirmed','fraud case stores human outcome');

select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000003',true);select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}',true);
select throws_ok($$select public.refresh_demand_forecast('52000000-0000-0000-0000-000000000001','ID','forecast-support')$$,'42501','forecast admin AAL2 required','support cannot publish forecast baseline');
select set_config('request.jwt.claim.sub','a0000000-0000-0000-0000-000000000005',true);select set_config('request.jwt.claims','{"sub":"a0000000-0000-0000-0000-000000000005","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$insert into scale_ids values('forecast',public.refresh_demand_forecast('52000000-0000-0000-0000-000000000001','ID','forecast-admin'))$$,'admin refreshes historical forecast baseline');
select ok((select p10<=p50 and p50<=p90 from public.demand_forecasts where id=(select id from scale_ids where kind='forecast')),'forecast interval remains ordered');
select is((select count(*) from public.ranking_model_versions where status='active' and traffic_percent=100),1::bigint,'one pinned active ranking baseline exists');

select * from finish();rollback;
