\set ON_ERROR_STOP on

do $$
begin
  if exists(select 1 from public.ledger_entries group by transaction_id having sum(amount)<>0) then raise exception 'restore verification failed: unbalanced ledger transaction';end if;
  if exists(select 1 from public.bookings where total_amount<>subtotal+platform_fee+tax_amount) then raise exception 'restore verification failed: booking totals inconsistent';end if;
  if (select count(*) from public.platform_feature_flags)<>5 then raise exception 'restore verification failed: launch controls incomplete';end if;
  if exists(select 1 from public.payment_holds h left join public.bookings b on b.id=h.booking_id where b.id is null) then raise exception 'restore verification failed: orphan payment hold';end if;
end$$;

select 'profiles' as entity,count(*) as restored_count from public.profiles
union all select 'providers',count(*) from public.providers
union all select 'jobs',count(*) from public.jobs
union all select 'bookings',count(*) from public.bookings
union all select 'ledger_transactions',count(*) from public.ledger_transactions
union all select 'audit_logs',count(*) from public.audit_logs
order by entity;
