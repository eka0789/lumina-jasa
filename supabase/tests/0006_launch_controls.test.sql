begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users(id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,aud,role) values
('90000000-0000-0000-0000-000000000001','launch-customer@example.test','',now(),'{}','{"full_name":"Launch Customer"}','authenticated','authenticated'),
('90000000-0000-0000-0000-000000000002','launch-admin@example.test','',now(),'{}','{"full_name":"Launch Admin"}','authenticated','authenticated');
insert into public.user_roles(user_id,role) values('90000000-0000-0000-0000-000000000002','admin');
create temporary table launch_ids(kind text primary key,id uuid);

select is((select count(*) from public.platform_feature_flags),5::bigint,'five critical launch controls are seeded');
set local role authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.set_platform_feature_flag('booking_intake',false,'Customer attempts control change.','launch-denied')$$,'42501','admin AAL2 required','customer cannot change launch control');

select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.set_platform_feature_flag('booking_intake',false,'Admin without strong authentication.','launch-aal1')$$,'42501','admin AAL2 required','admin requires AAL2');
select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.set_platform_feature_flag('booking_intake',false,'Pause during controlled launch exercise.','launch-off')$$,'AAL2 admin disables booking intake');
select is((select enabled from public.platform_feature_flags where name='booking_intake'),false,'booking intake flag is disabled');

select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.submit_job_request('52000000-0000-0000-0000-000000000001','Paused launch job','Permintaan harus ditolak selama kill switch aktif.',now()+interval '1 day',now()+interval '2 days',100000,400000,'paused-job')$$,'55000','feature temporarily disabled: booking_intake','disabled intake fails closed');

select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.set_platform_feature_flag('booking_intake',true,'Resume after controlled launch exercise.','launch-on')$$,'AAL2 admin re-enables booking intake');
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into launch_ids values('job',public.submit_job_request('52000000-0000-0000-0000-000000000001','Resumed launch job','Permintaan berhasil setelah kontrol diaktifkan kembali.',now()+interval '1 day',now()+interval '2 days',100000,400000,'resumed-job'))$$,'re-enabled intake accepts new work');

select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal1"}',true);
select throws_ok($$select public.get_launch_metrics()$$,'42501','operations AAL2 required','operations metrics require AAL2');
select set_config('request.jwt.claims','{"sub":"90000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2"}',true);
select ok(public.get_launch_metrics() ?& array['activeBookings','openDisputes','pendingRefunds','openModeration','outboxBacklog','aiFallback24h'],'launch metrics expose all required control signals');
select is((select count(*) from public.audit_logs where action='launch.feature_flag_changed' and resource_id='booking_intake'),2::bigint,'every flag transition is audited');

select * from finish();rollback;
