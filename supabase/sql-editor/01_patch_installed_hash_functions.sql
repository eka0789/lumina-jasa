-- Recovery for a schema where 0006_transaction_pilot.sql was already installed
-- before its hash expressions were made independent of the pgcrypto schema.
-- Run this once, then rerun 02_demo_seed.sql from the beginning.

begin;

-- The installed function bodies still call digest(). Limit lookup to trusted
-- system/extension schemas; never add public to a SECURITY DEFINER search_path.
alter function public.submit_job_request(uuid,text,text,timestamptz,timestamptz,bigint,bigint,text)
  set search_path = pg_catalog, extensions;
alter function public.accept_quote_and_create_booking(uuid,timestamptz,text)
  set search_path = pg_catalog, extensions;
alter function public.transition_booking(uuid,text,text,text)
  set search_path = pg_catalog, extensions;

commit;

select
  p.proname,
  p.proconfig @> array['search_path=pg_catalog, extensions'] as patched
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('submit_job_request','accept_quote_and_create_booking','transition_booking')
order by p.proname;
