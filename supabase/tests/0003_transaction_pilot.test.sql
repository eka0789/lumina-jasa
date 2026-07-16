begin;

create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users(id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,aud,role) values
('60000000-0000-0000-0000-000000000001','pilot-customer@example.test','',now(),'{}','{"full_name":"Pilot Customer"}','authenticated','authenticated'),
('60000000-0000-0000-0000-000000000002','pilot-provider@example.test','',now(),'{}','{"full_name":"Pilot Provider"}','authenticated','authenticated');

insert into public.providers(id,owner_user_id,display_name,slug,status,verification_status)
values('61000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000002','Pilot Teknik','pilot-teknik-transaction','active','verified');
insert into public.provider_members(provider_id,user_id,role,status)
values('61000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000002','owner','active');
insert into public.provider_services(id,provider_id,service_id,title,pricing_type,base_price,status)
values('62000000-0000-0000-0000-000000000001','61000000-0000-0000-0000-000000000001','52000000-0000-0000-0000-000000000001','Servis AC Pilot','from',200000,'active');
insert into public.provider_availability(provider_id,weekday,starts_at,ends_at,capacity)
select '61000000-0000-0000-0000-000000000001', day, '00:00', '23:59', 1 from generate_series(0,6) day;

create temporary table pilot_ids(kind text primary key,id uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"60000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into pilot_ids values('job',public.submit_job_request('52000000-0000-0000-0000-000000000001','AC tidak dingin','AC kamar tidak dingin sejak kemarin dan perlu diperiksa.',date_trunc('day',now()+interval '2 days')+interval '8 hours',date_trunc('day',now()+interval '2 days')+interval '18 hours',150000,500000,'pilot-job-key'))$$,'customer submits structured request');
select is((select count(*)::integer from public.job_matches where job_id=(select id from pilot_ids where kind='job')),1,'matching rules select eligible verified provider');

select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"60000000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into pilot_ids values('quote',public.submit_job_quote((select id from pilot_ids where kind='job'),'62000000-0000-0000-0000-000000000001',300000,120,'Termasuk pemeriksaan dan perbaikan ringan.',now()+interval '2 days'))$$,'matched provider submits quote');

select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"60000000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1"}',true);
select lives_ok($$insert into pilot_ids values('booking',public.accept_quote_and_create_booking((select id from pilot_ids where kind='quote'),date_trunc('day',now()+interval '2 days')+interval '10 hours','pilot-booking-key'))$$,'customer accepts quote and reserves schedule');
select is((select status from public.bookings where id=(select id from pilot_ids where kind='booking')),'awaiting_payment','booking awaits payment');
select lives_ok($$select public.capture_sandbox_payment((select id from pilot_ids where kind='booking'))$$,'customer captures sandbox payment');
set constraints all immediate;
select is((select coalesce(sum(e.amount),0)::bigint from public.ledger_entries e join public.ledger_transactions t on t.id=e.transaction_id where t.reference_type='payment_intent'),0::bigint,'payment ledger transaction is balanced');
select is((select count(*)::integer from public.invoices where booking_id=(select id from pilot_ids where kind='booking')),1,'captured payment issues one invoice');
select is((select count(*)::integer from public.conversations where booking_id=(select id from pilot_ids where kind='booking')),1,'booking creates durable conversation');
select throws_ok($$select public.transition_booking((select id from pilot_ids where kind='booking'),'in_progress','skip states','invalid-transition')$$,'22023','invalid booking transition','customer cannot skip workflow states');

select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000002',true);
select lives_ok($test$do $$ begin
  perform public.transition_booking((select id from pilot_ids where kind='booking'),'accepted','','transition-1');
  perform public.transition_booking((select id from pilot_ids where kind='booking'),'en_route','','transition-2');
  perform public.transition_booking((select id from pilot_ids where kind='booking'),'in_progress','','transition-3');
  perform public.transition_booking((select id from pilot_ids where kind='booking'),'provider_completed','','transition-4');
end $$;$test$,'provider follows allowed fulfilment transitions');

select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000001',true);
select lives_ok($$select public.transition_booking((select id from pilot_ids where kind='booking'),'customer_confirmed','','transition-5')$$,'customer confirms provider completion');
select is((select status from public.payment_holds where booking_id=(select id from pilot_ids where kind='booking')),'released','confirmation releases payment hold');
select is((select count(*)::integer from public.job_status_events where booking_id=(select id from pilot_ids where kind='booking')),7,'immutable timeline records every state');

select * from finish();
rollback;
