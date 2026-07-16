-- Run after the migration bundle and demo seed.
-- Each check should return true; the final ledger query should return no rows.

select to_regclass('public.profiles') is not null as schema_installed;
select count(*) = 10 as migration_feature_count
from information_schema.tables
where table_schema='public' and table_name in (
  'profiles','providers','jobs','bookings','payment_intents',
  'privacy_requests','moderation_cases','platform_feature_flags','fraud_cases','demand_forecasts'
);
select count(*) = 8 as demo_users from auth.users where email like '%@demo.luminajasa.id';
select count(*) >= 1 as verified_provider from public.providers where status='active' and verification_status='verified';
select count(*) >= 1 as customer_booking from public.bookings b join auth.users u on u.id=b.customer_id where u.email='customer@demo.luminajasa.id';
select count(*) >= 1 as moderation_queue from public.moderation_cases where status in ('open','appealed');
select count(*) >= 1 as verification_queue from public.verification_cases where status in ('pending','processing','manual_review');
select count(*) >= 1 as fraud_queue from public.fraud_cases where status in ('open','reviewing','appealed');
select count(*) >= 1 as forecast_ready from public.demand_forecasts;

-- No rows means every posted ledger transaction is balanced.
select t.id,t.reference_type,sum(e.amount) as imbalance
from public.ledger_transactions t
join public.ledger_entries e on e.transaction_id=t.id
where t.status='posted'
group by t.id,t.reference_type
having sum(e.amount)<>0;
