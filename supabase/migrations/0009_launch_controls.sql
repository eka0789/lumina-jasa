begin;

create table public.platform_feature_flags (
  name text primary key check (name in ('booking_intake','payment_capture','payout_release','ai_intake','tracking_publish')),
  enabled boolean not null default true,
  reason text not null default 'Initial launch setting',
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

insert into public.platform_feature_flags(name) values('booking_intake'),('payment_capture'),('payout_release'),('ai_intake'),('tracking_publish');
alter table public.platform_feature_flags enable row level security;
grant select on public.platform_feature_flags to authenticated;
create policy launch_flags_staff_read on public.platform_feature_flags for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);

create or replace function private.require_feature_enabled()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if not coalesce((select enabled from public.platform_feature_flags where name=tg_argv[0]),false) then raise exception 'feature temporarily disabled: %',tg_argv[0] using errcode='55000';end if;
 return new;
end;$$;
revoke all on function private.require_feature_enabled() from public;

create trigger guard_booking_intake before insert on public.jobs for each row execute function private.require_feature_enabled('booking_intake');
create trigger guard_payment_capture before update of status on public.payment_intents for each row when (new.status='captured' and old.status is distinct from new.status) execute function private.require_feature_enabled('payment_capture');
create trigger guard_payout_release before insert on public.payouts for each row execute function private.require_feature_enabled('payout_release');
create trigger guard_ai_intake before insert on public.ai_runs for each row when (new.module='smart_intake') execute function private.require_feature_enabled('ai_intake');
create trigger guard_tracking_publish before insert on public.tracking_points for each row execute function private.require_feature_enabled('tracking_publish');

create or replace function public.set_platform_feature_flag(p_name text,p_enabled boolean,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());old_value boolean;
begin
 if not(private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'admin AAL2 required' using errcode='42501';end if;
 if length(trim(p_reason))<10 then raise exception 'control reason required' using errcode='22023';end if;
 select enabled into old_value from public.platform_feature_flags where name=p_name for update;if old_value is null then raise exception 'unknown feature flag' using errcode='22023';end if;
 update public.platform_feature_flags set enabled=p_enabled,reason=trim(p_reason),updated_by=actor_id,updated_at=now() where name=p_name;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,before_hash,after_hash,correlation_id) values(actor_id,'staff','launch.feature_flag_changed','platform_feature_flag',p_name,trim(p_reason),old_value::text,p_enabled::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function public.get_launch_metrics()
returns jsonb language plpgsql security definer set search_path='' stable as $$
begin
 if not(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'operations AAL2 required' using errcode='42501';end if;
 return jsonb_build_object(
  'activeBookings',(select count(*) from public.bookings where status in('confirmed','accepted','en_route','in_progress','provider_completed')),
  'openDisputes',(select count(*) from public.disputes where status not in('resolved','closed')),
  'pendingRefunds',(select count(*) from public.refunds where status='requested'),
  'openModeration',(select count(*) from public.moderation_cases where status in('open','appealed')),
  'outboxBacklog',(select count(*) from public.outbox_events where published_at is null and available_at<=now()),
  'aiFallback24h',(select count(*) from public.ai_runs where status='fallback' and created_at>=now()-interval '24 hours')
 );
end;$$;

revoke all on function public.set_platform_feature_flag(text,boolean,text,text),public.get_launch_metrics() from public;
grant execute on function public.set_platform_feature_flag(text,boolean,text,text),public.get_launch_metrics() to authenticated;

commit;
