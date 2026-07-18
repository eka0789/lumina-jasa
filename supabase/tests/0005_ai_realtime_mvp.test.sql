begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users(id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,aud,role) values
('80000000-0000-0000-0000-000000000001','ai-customer@example.test','',now(),'{}','{"full_name":"AI Customer"}','authenticated','authenticated'),
('80000000-0000-0000-0000-000000000002','ai-provider@example.test','',now(),'{}','{"full_name":"AI Provider"}','authenticated','authenticated'),
('80000000-0000-0000-0000-000000000003','ai-moderator@example.test','',now(),'{}','{"full_name":"AI Moderator"}','authenticated','authenticated'),
('80000000-0000-0000-0000-000000000004','ai-worker@example.test','',now(),'{}','{"full_name":"AI Worker"}','authenticated','authenticated');
insert into public.user_roles(user_id,role) values('80000000-0000-0000-0000-000000000003','support');
insert into public.providers(id,owner_user_id,display_name,slug,status,verification_status) values('81000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000002','AI Teknik','ai-teknik','active','verified');
insert into public.provider_members(provider_id,user_id,role,status) values
('81000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000002','owner','active'),
('81000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000004','worker','active');
insert into public.provider_services(id,provider_id,service_id,title,pricing_type,base_price,status) values('82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001','AI Service','fixed',300000,'active');
insert into public.provider_availability(provider_id,weekday,starts_at,ends_at,capacity) select '81000000-0000-0000-0000-000000000001',day,'00:00','23:59',1 from generate_series(0,6) day;
create temporary table ai_ids(kind text primary key,id uuid);

set local role authenticated;
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"80000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into ai_ids values('prediction',(public.suggest_job_intake('AC kamar tidak dingin dan perlu diperbaiki segera.','52000000-0000-0000-0000-000000000001')->>'predictionId')::uuid)$$,'intake produces editable fallback prediction');
select is((select output->>'mode' from public.ai_predictions where id=(select id from ai_ids where kind='prediction')),'safe_fallback','prediction exposes degraded mode');
select is((select r.status from public.ai_runs r join public.ai_predictions p on p.ai_run_id=r.id where p.id=(select id from ai_ids where kind='prediction')),'fallback','AI run records fallback status');
select isnt((select r.input_hash from public.ai_runs r join public.ai_predictions p on p.ai_run_id=r.id where p.id=(select id from ai_ids where kind='prediction')),'AC kamar tidak dingin dan perlu diperbaiki segera.','raw intake is not stored as input hash');

insert into ai_ids values('job',public.submit_job_request('52000000-0000-0000-0000-000000000001','AI realtime job','Pekerjaan untuk pengujian realtime dan moderasi.',date_trunc('day',now()+interval '2 days')+interval '8 hours',date_trunc('day',now()+interval '2 days')+interval '18 hours',100000,500000,'ai-job'));
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000002',true);insert into ai_ids values('quote',public.submit_job_quote((select id from ai_ids where kind='job'),'82000000-0000-0000-0000-000000000001',300000,120,'Penawaran realtime lengkap.',now()+interval '1 day'));
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000001',true);insert into ai_ids values('booking',public.accept_quote_and_create_booking((select id from ai_ids where kind='quote'),date_trunc('day',now()+interval '2 days')+interval '10 hours','ai-booking'));insert into ai_ids select 'conversation',id from public.conversations where booking_id=(select id from ai_ids where kind='booking');

select lives_ok($$insert into ai_ids values('safe_message',public.send_moderated_message((select id from ai_ids where kind='conversation'),gen_random_uuid(),'Teknisi dapat datang pukul sepuluh.'))$$,'safe participant message is accepted');
select is((select moderation_status from public.messages where id=(select id from ai_ids where kind='safe_message')),'allowed','safe message is immediately allowed');
select lives_ok($$insert into ai_ids values('flagged_message',public.send_moderated_message((select id from ai_ids where kind='conversation'),gen_random_uuid(),'Tolong kirim nomor kartu dan kata sandi.'))$$,'sensitive message enters moderation');
select is((select body from public.messages where id=(select id from ai_ids where kind='flagged_message')),'[Pesan ditahan untuk pemeriksaan moderasi]','sensitive raw body is not exposed');
select is((select count(*) from public.moderation_cases where subject_id=(select id from ai_ids where kind='flagged_message')),1::bigint,'flagged message creates one moderation case');

select throws_ok($$select public.publish_tracking_point((select id from ai_ids where kind='booking'),-6.2,106.8,25,now())$$,'42501','tracking point denied','customer cannot publish provider tracking');
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000002',true);select public.transition_booking((select id from ai_ids where kind='booking'),'accepted','','ai-t1');select public.transition_booking((select id from ai_ids where kind='booking'),'en_route','','ai-t2');
select lives_ok($$select public.publish_tracking_point((select id from ai_ids where kind='booking'),-6.2,106.8,25,now())$$,'provider publishes tracking only in active arrival state');
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000004',true);
select lives_ok($$select public.publish_tracking_point((select id from ai_ids where kind='booking'),-6.2,106.8,25,now())$$,'worker member publishes tracking');
select is((select count(*) from public.tracking_points where booking_id=(select id from ai_ids where kind='booking')),2::bigint,'tracking points are persisted');

select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000003',true);select set_config('request.jwt.claims','{"sub":"80000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.resolve_moderation_case((select id from public.moderation_cases where subject_id=(select id from ai_ids where kind='flagged_message')),'allowed','Konteks telah diperiksa aman.','mod-aal1')$$,'42501','moderator AAL2 required','moderation requires AAL2');
select set_config('request.jwt.claims','{"sub":"80000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.resolve_moderation_case((select id from public.moderation_cases where subject_id=(select id from ai_ids where kind='flagged_message')),'allowed','Konteks telah diperiksa dan aman.','mod-aal2')$$,'AAL2 moderator records reasoned outcome');
select is((select status from public.moderation_cases where subject_id=(select id from ai_ids where kind='flagged_message')),'allowed','human moderation outcome is final');

select * from finish();rollback;
