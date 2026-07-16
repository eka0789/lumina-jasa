begin;

create table public.ranking_model_versions (
  id uuid primary key default gen_random_uuid(), name text not null unique, status text not null check(status in('shadow','canary','active','retired')),
  traffic_percent smallint not null default 0 check(traffic_percent between 0 and 100), feature_schema text not null,
  weights jsonb not null, evaluation jsonb not null default '{}', created_at timestamptz not null default now(), activated_at timestamptz
);
insert into public.ranking_model_versions(name,status,traffic_percent,feature_schema,weights,evaluation,activated_at) values('deterministic-rules-v1','active',100,'ranking.v1','{"relevance":0.30,"rating":0.25,"response":0.20,"experience":0.15,"area":0.10}','{"baseline":true}',now());

create table public.demand_forecasts (
  id uuid primary key default gen_random_uuid(), service_id uuid references public.services(id), region_code text not null default 'ID',
  horizon_start date not null, horizon_end date not null, p10 numeric(12,2) not null, p50 numeric(12,2) not null, p90 numeric(12,2) not null,
  model_version text not null, drivers jsonb not null default '{}', created_at timestamptz not null default now(), check(p10<=p50 and p50<=p90)
);
alter table public.ranking_model_versions enable row level security;alter table public.demand_forecasts enable row level security;
grant select on public.ranking_model_versions,public.demand_forecasts,public.fraud_signals,public.fraud_cases to authenticated;
create policy scale_models_staff_read on public.ranking_model_versions for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy forecasts_staff_read on public.demand_forecasts for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy fraud_signals_staff_read on public.fraud_signals for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));
create policy fraud_cases_staff_read on public.fraud_cases for select to authenticated using(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin'));

create or replace function public.submit_emergency_job_request(p_service_id uuid,p_title text,p_description text,p_budget_max bigint,p_safety_confirmed boolean,p_idempotency_key text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());new_id uuid;existing_id uuid;
begin
 if actor_id is null then raise exception 'authentication required' using errcode='28000';end if;
 select resource_id into existing_id from public.idempotency_keys where principal_id=actor_id and scope='job.emergency' and key=p_idempotency_key and expires_at>now();if existing_id is not null then return existing_id;end if;
 if not p_safety_confirmed or length(trim(p_title))<5 or length(trim(p_description))<20 or p_budget_max<=0 then raise exception 'emergency request incomplete' using errcode='22023';end if;
 if not exists(select 1 from public.services where id=p_service_id and status='active' and emergency_enabled) then raise exception 'service not enabled for emergency dispatch' using errcode='22023';end if;
 insert into public.jobs(customer_id,service_id,title,description,booking_type,status,requested_start,requested_end,budget_min,budget_max) values(actor_id,p_service_id,trim(p_title),trim(p_description),'emergency','requested',now()+interval '15 minutes',now()+interval '4 hours',0,p_budget_max) returning id into new_id;
 insert into public.job_matches(job_id,provider_id,provider_service_id,rank,score,score_components,reason_codes,model_version,status)
 select new_id,ps.provider_id,ps.id,row_number() over(order by p.response_rate desc,p.rating_avg desc,p.id)::integer,least(1,(p.response_rate/100*0.55+p.rating_avg/5*0.45))::numeric(8,5),jsonb_build_object('response_rate',p.response_rate,'rating',p.rating_avg),array['emergency_enabled','verified_provider','response_priority'],'emergency-rules-v1','invited' from public.provider_services ps join public.providers p on p.id=ps.provider_id where ps.service_id=p_service_id and ps.status='active' and p.status='active' and p.verification_status='verified' order by p.response_rate desc,p.rating_avg desc limit 5;
 if exists(select 1 from public.job_matches where job_id=new_id) then update public.jobs set status='matched' where id=new_id;end if;
 insert into public.notifications(user_id,event_type,channel,template_version,payload)
 select p.owner_user_id,'emergency.job_invited',channel,'v1',jsonb_build_object('job_id',new_id) from public.job_matches m join public.providers p on p.id=m.provider_id cross join lateral (select 'in_app'::text channel union all select np.channel from public.notification_preferences np where np.user_id=p.owner_user_id and np.event_type='emergency.job_invited' and np.enabled and np.channel in('email','push','whatsapp','sms')) c where m.job_id=new_id;
 insert into public.idempotency_keys(principal_id,scope,key,request_hash,response_status,resource_id,expires_at) values(actor_id,'job.emergency',p_idempotency_key,pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(concat_ws('|',p_service_id,p_title,p_budget_max),'UTF8')),'hex'),201,new_id,now()+interval '24 hours');
 insert into public.outbox_events(aggregate_type,aggregate_id,event_type,payload,correlation_id) values('job',new_id,'emergency.dispatch_requested',jsonb_build_object('job_id',new_id),p_idempotency_key);return new_id;
end;$$;

create or replace function public.record_manual_fraud_signal(p_user_id uuid,p_booking_id uuid,p_signal_type text,p_score numeric,p_reason text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());new_id uuid;begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud reviewer AAL2 required' using errcode='42501';end if;
 if p_score not between 0 and 1 or length(trim(p_reason))<10 or p_user_id is null then raise exception 'invalid fraud signal' using errcode='22023';end if;
 insert into public.fraud_signals(user_id,booking_id,signal_type,source,score,payload,expires_at) values(p_user_id,p_booking_id,p_signal_type,'manual_review',p_score,jsonb_build_object('reason',trim(p_reason)),now()+interval '90 days') returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','fraud.signal_recorded','fraud_signal',new_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;end;$$;

create or replace function public.open_fraud_case(p_user_id uuid,p_booking_id uuid,p_reason text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());risk numeric;new_id uuid;begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud reviewer AAL2 required' using errcode='42501';end if;
 if length(trim(p_reason))<10 then raise exception 'case reason required' using errcode='22023';end if;
 select least(100,coalesce(sum(score*100),0)) into risk from public.fraud_signals where user_id=p_user_id and (p_booking_id is null or booking_id=p_booking_id) and (expires_at is null or expires_at>now());if risk=0 then raise exception 'no active signals' using errcode='22023';end if;
 insert into public.fraud_cases(subject_user_id,booking_id,risk_score,severity,status) values(p_user_id,p_booking_id,risk,case when risk>=80 then 'critical' when risk>=60 then 'high' when risk>=30 then 'medium' else 'low' end,'open') returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id,metadata) values(actor_id,'staff','fraud.case_opened','fraud_case',new_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text),jsonb_build_object('risk_score',risk));return new_id;end;$$;

create or replace function public.decide_fraud_case(p_case_id uuid,p_decision text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());begin
 if not(private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'fraud decision AAL2 required' using errcode='42501';end if;
 if p_decision not in('cleared','confirmed') or length(trim(p_reason))<10 then raise exception 'reasoned fraud decision required' using errcode='22023';end if;
 update public.fraud_cases set status=p_decision,assigned_to=actor_id,decision_reason=trim(p_reason),closed_at=now() where id=p_case_id and status in('open','reviewing','appealed');if not found then raise exception 'active fraud case not found' using errcode='P0002';end if;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','fraud.case_'||p_decision,'fraud_case',p_case_id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));end;$$;

create or replace function public.refresh_demand_forecast(p_service_id uuid,p_region_code text,p_correlation_id text)
returns uuid language plpgsql security definer set search_path='' as $$declare actor_id uuid:=(select auth.uid());daily numeric;new_id uuid;begin
 if not(private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'forecast admin AAL2 required' using errcode='42501';end if;
 select coalesce(count(*)::numeric/28,0) into daily from public.jobs where service_id=p_service_id and created_at>=now()-interval '28 days';
 insert into public.demand_forecasts(service_id,region_code,horizon_start,horizon_end,p10,p50,p90,model_version,drivers) values(p_service_id,upper(p_region_code),current_date+1,current_date+7,greatest(0,daily*7*0.65),daily*7,daily*7*1.45,'historical-baseline-v1',jsonb_build_object('history_days',28,'method','daily_average')) returning id into new_id;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,correlation_id) values(actor_id,'staff','forecast.refreshed','demand_forecast',new_id::text,coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));return new_id;end;$$;

revoke all on function public.submit_emergency_job_request(uuid,text,text,bigint,boolean,text),public.record_manual_fraud_signal(uuid,uuid,text,numeric,text,text),public.open_fraud_case(uuid,uuid,text,text),public.decide_fraud_case(uuid,text,text,text),public.refresh_demand_forecast(uuid,text,text) from public;
grant execute on function public.submit_emergency_job_request(uuid,text,text,bigint,boolean,text),public.record_manual_fraud_signal(uuid,uuid,text,numeric,text,text),public.open_fraud_case(uuid,uuid,text,text),public.decide_fraud_case(uuid,text,text,text),public.refresh_demand_forecast(uuid,text,text) to authenticated;

commit;
