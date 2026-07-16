begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

insert into auth.users(id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,aud,role) values
('70000000-0000-0000-0000-000000000001','trust-customer@example.test','',now(),'{}','{"full_name":"Trust Customer"}','authenticated','authenticated'),
('70000000-0000-0000-0000-000000000002','trust-provider@example.test','',now(),'{}','{"full_name":"Trust Provider"}','authenticated','authenticated'),
('70000000-0000-0000-0000-000000000003','trust-support@example.test','',now(),'{}','{"full_name":"Trust Support"}','authenticated','authenticated'),
('70000000-0000-0000-0000-000000000004','trust-finance@example.test','',now(),'{}','{"full_name":"Trust Finance"}','authenticated','authenticated'),
('70000000-0000-0000-0000-000000000005','business-approver@example.test','',now(),'{}','{"full_name":"Business Approver"}','authenticated','authenticated'),
('70000000-0000-0000-0000-000000000006','privacy-compliance@example.test','',now(),'{}','{"full_name":"Privacy Compliance"}','authenticated','authenticated');
insert into public.user_roles(user_id,role) values
('70000000-0000-0000-0000-000000000003','support'),('70000000-0000-0000-0000-000000000004','finance'),('70000000-0000-0000-0000-000000000006','compliance');
insert into public.providers(id,owner_user_id,display_name,slug,status,verification_status) values('71000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000002','Trust Teknik','trust-teknik','active','verified');
insert into public.provider_members(provider_id,user_id,role,status) values('71000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000002','owner','active');
insert into public.provider_services(id,provider_id,service_id,title,pricing_type,base_price,status) values('72000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001','Trust Service','fixed',300000,'active');
insert into public.provider_availability(provider_id,weekday,starts_at,ends_at,capacity) select '71000000-0000-0000-0000-000000000001',day,'00:00','23:59',1 from generate_series(0,6) day;
create temporary table trust_ids(kind text primary key,id uuid);

set local role authenticated;
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"70000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
insert into trust_ids values('job',public.submit_job_request('52000000-0000-0000-0000-000000000001','Trust job utama','Pekerjaan utama untuk pengujian sengketa dan refund.',date_trunc('day',now()+interval '2 days')+interval '8 hours',date_trunc('day',now()+interval '2 days')+interval '18 hours',100000,500000,'trust-job'));
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000002',true);insert into trust_ids values('quote',public.submit_job_quote((select id from trust_ids where kind='job'),'72000000-0000-0000-0000-000000000001',300000,120,'Penawaran trust lengkap dan terukur.',now()+interval '1 day'));
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);insert into trust_ids values('booking',public.accept_quote_and_create_booking((select id from trust_ids where kind='quote'),date_trunc('day',now()+interval '2 days')+interval '10 hours','trust-booking'));select public.capture_sandbox_payment((select id from trust_ids where kind='booking'));
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000002',true);select public.transition_booking((select id from trust_ids where kind='booking'),'accepted','','trust-t1');select public.transition_booking((select id from trust_ids where kind='booking'),'en_route','','trust-t2');select public.transition_booking((select id from trust_ids where kind='booking'),'in_progress','','trust-t3');select public.transition_booking((select id from trust_ids where kind='booking'),'provider_completed','','trust-t4');
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);select public.transition_booking((select id from trust_ids where kind='booking'),'customer_confirmed','','trust-t5');

select lives_ok($$insert into trust_ids values('review',public.submit_verified_review((select id from trust_ids where kind='booking'),5,'Sangat baik','Pekerjaan selesai dengan hasil yang baik.'))$$,'eligible customer submits verified review');
select throws_ok($$select public.submit_verified_review((select id from trust_ids where kind='booking'),4,'Lagi','Ulasan kedua')$$,'23505','duplicate key value violates unique constraint "reviews_booking_id_customer_id_key"','one verified review per booking');
select lives_ok($$insert into trust_ids values('dispute',public.open_booking_dispute((select id from trust_ids where kind='booking'),'service_quality','Ada bagian hasil pekerjaan yang perlu diselesaikan kembali.',100000,'trust-dispute'))$$,'participant opens eligible dispute');
select is((select status from public.payment_holds where booking_id=(select id from trust_ids where kind='booking')),'frozen','dispute freezes payment hold');
select lives_ok($$select public.add_dispute_evidence_note((select id from trust_ids where kind='dispute'),'Percakapan menunjukkan bagian yang perlu dikerjakan ulang.','trust-evidence')$$,'participant adds auditable dispute evidence note');

select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000003',true);select set_config('request.jwt.claims','{"sub":"70000000-0000-0000-0000-000000000003","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$insert into trust_ids values('refund',public.recommend_dispute_resolution((select id from trust_ids where kind='dispute'),'Bukti mendukung refund sebagian untuk perbaikan yang belum selesai.',100000,'trust-resolution'))$$,'support recommends reasoned partial refund');
select throws_ok($$select public.approve_sandbox_refund((select id from trust_ids where kind='refund'),'Support mencoba approval','bad-approval')$$,'42501','finance AAL2 required','support cannot approve refund');

select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000004',true);select set_config('request.jwt.claims','{"sub":"70000000-0000-0000-0000-000000000004","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.approve_sandbox_refund((select id from trust_ids where kind='refund'),'Refund sesuai bukti sengketa.','trust-refund')$$,'independent finance approves refund');set constraints all immediate;
select is((select coalesce(sum(amount),0)::bigint from public.ledger_entries where transaction_id=(select id from public.ledger_transactions where reference_type='refund' and reference_id=(select id from trust_ids where kind='refund'))),0::bigint,'refund ledger transaction is balanced');
select is((select status from public.disputes where id=(select id from trust_ids where kind='dispute')),'resolved','approved refund resolves dispute');

select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claims','{"sub":"70000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into trust_ids values('business',public.create_business('Trust Business PT','Trust Business','billing@example.test','business-create'))$$,'user creates business with owner membership');
select lives_ok($$select public.add_business_member((select id from trust_ids where kind='business'),'business-approver@example.test','approver',0,'member-add')$$,'owner adds independent approver');
select lives_ok($$insert into trust_ids values('rule',public.create_business_approval_rule((select id from trust_ids where kind='business'),'Belanja di atas 100 ribu',100000,1,'rule-create'))$$,'owner creates effective approval rule');
insert into trust_ids values('business_job',public.submit_job_request('52000000-0000-0000-0000-000000000001','Business trust job','Permintaan bisnis yang membutuhkan persetujuan independen.',date_trunc('day',now()+interval '4 days')+interval '8 hours',date_trunc('day',now()+interval '4 days')+interval '18 hours',100000,500000,'business-job'));
select lives_ok($$insert into trust_ids values('approval',public.request_business_job_approval((select id from trust_ids where kind='business'),(select id from trust_ids where kind='business_job'),330000,'approval-request'))$$,'requester creates snapshotted approval request');
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000002',true);insert into trust_ids values('business_quote',public.submit_job_quote((select id from trust_ids where kind='business_job'),'72000000-0000-0000-0000-000000000001',300000,120,'Penawaran bisnis membutuhkan approval.',now()+interval '1 day'));
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);
select throws_ok($$select public.accept_quote_and_create_booking((select id from trust_ids where kind='business_quote'),date_trunc('day',now()+interval '4 days')+interval '10 hours','business-booking-before-approval')$$,'42501','business approval required','booking is blocked before business approval');
select throws_ok($$select public.decide_business_approval((select id from trust_ids where kind='approval'),'approved','Menyetujui permintaan sendiri','self-approval')$$,'42501','independent approver required','requester cannot self-approve');
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000005',true);
select lives_ok($$select public.decide_business_approval((select id from trust_ids where kind='approval'),'approved','Anggaran dan kebutuhan telah diperiksa.','approval-decision')$$,'independent approver approves business request');
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000001',true);
select lives_ok($$insert into trust_ids values('business_booking',public.accept_quote_and_create_booking((select id from trust_ids where kind='business_quote'),date_trunc('day',now()+interval '4 days')+interval '10 hours','business-booking-approved'))$$,'approved business request can create booking');

select lives_ok($$insert into trust_ids values('privacy',public.submit_privacy_request('export','Mohon ekspor seluruh data akun saya.','privacy-submit'))$$,'user submits auditable privacy request');
select set_config('request.jwt.claim.sub','70000000-0000-0000-0000-000000000006',true);select set_config('request.jwt.claims','{"sub":"70000000-0000-0000-0000-000000000006","role":"authenticated","aal":"aal2"}',true);
select lives_ok($$select public.complete_privacy_request((select id from trust_ids where kind='privacy'),'completed','Identitas diverifikasi dan ekspor disediakan.','privacy-complete')$$,'compliance AAL2 completes privacy request');
select is((select status from public.privacy_requests where id=(select id from trust_ids where kind='privacy')),'completed','privacy outcome is visible to requester');

select * from finish();rollback;
