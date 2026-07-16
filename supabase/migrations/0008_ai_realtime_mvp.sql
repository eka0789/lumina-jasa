begin;

create table public.moderation_cases (
  id uuid primary key default gen_random_uuid(),
  subject_type text not null check (subject_type in ('review','message')),
  subject_id uuid not null,
  status text not null default 'open' check (status in ('open','allowed','blocked','appealed','closed')),
  labels text[] not null default '{}',
  confidence numeric(6,5) not null check (confidence between 0 and 1),
  evidence jsonb not null default '{}',
  assigned_to uuid references public.profiles(id),
  resolution_reason text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.moderation_cases enable row level security;
grant select on public.moderation_cases to authenticated;
create policy moderation_staff_read on public.moderation_cases for select to authenticated using (
  private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')
);

revoke insert on public.messages from authenticated;
revoke insert,update on public.reviews from authenticated;

create or replace function public.suggest_job_intake(p_description text,p_service_id uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());service_row public.services;run_id uuid;prediction_id uuid;confidence numeric(6,5);p50 bigint;result jsonb;matched boolean:=false;
begin
 if actor_id is null or length(trim(p_description))<12 then raise exception 'description too short' using errcode='22023';end if;
 if p_service_id is not null then select * into service_row from public.services where id=p_service_id and status='active';matched:=service_row.id is not null;end if;
 if service_row.id is null then select * into service_row from public.services where status='active' and lower(p_description) like '%'||lower(name)||'%' order by sort_order,id limit 1;matched:=service_row.id is not null;end if;
 if service_row.id is null then select * into service_row from public.services where status='active' order by sort_order,id limit 1;end if;
 if service_row.id is null then raise exception 'active service unavailable' using errcode='P0002';end if;
 select coalesce(percentile_disc(0.5) within group(order by base_price),250000)::bigint into p50 from public.provider_services where service_id=service_row.id and status='active' and base_price is not null;
 confidence:=case when matched then 0.62 else 0.32 end;
 insert into public.ai_runs(module,subject_type,model_provider,model_version,prompt_version,schema_version,status,input_hash,trace_id,completed_at)
 values('smart_intake','user', 'deterministic_baseline','baseline-v1','intake-id-v1','1','fallback',pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(trim(p_description),'UTF8')),'hex'),gen_random_uuid()::text,now()) returning id into run_id;
 result:=jsonb_build_object('serviceId',service_row.id,'title',left(trim(p_description),80),'budgetMin',greatest(0,(p50*70)/100),'budgetMax',(p50*140)/100,'durationMinutes',coalesce(service_row.default_duration_minutes,120),'confidence',confidence,'mode','safe_fallback','assumptions',jsonb_build_array('Harga memakai median katalog aktif','Jadwal dan detail tetap harus dikonfirmasi pengguna'));
 insert into public.ai_predictions(ai_run_id,prediction_type,output,confidence,explanation,accepted_by) values(run_id,'structured_intake',result-'title',confidence,jsonb_build_object('reason_codes',case when matched then jsonb_build_array('service_term_match','catalog_price_baseline') else jsonb_build_array('manual_service_confirmation','catalog_price_baseline') end),actor_id) returning id into prediction_id;
 return result||jsonb_build_object('predictionId',prediction_id);
end;$$;

create or replace function public.send_moderated_message(p_conversation_id uuid,p_client_id uuid,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());message_id uuid;unsafe boolean;safe_body text;moderation_status text;
begin
 if actor_id is null or length(trim(p_body))<1 or length(p_body)>4000 or not exists(select 1 from public.conversation_participants where conversation_id=p_conversation_id and user_id=actor_id and left_at is null) then raise exception 'message denied' using errcode='42501';end if;
 unsafe:=lower(p_body) ~ '(ancam|bunuh|penipuan|nomor kartu|kata sandi)';safe_body:=case when unsafe then '[Pesan ditahan untuk pemeriksaan moderasi]' else trim(p_body) end;moderation_status:=case when unsafe then 'flagged' else 'allowed' end;
 insert into public.messages(conversation_id,sender_user_id,client_id,kind,body,moderation_status) values(p_conversation_id,actor_id,p_client_id,'text',safe_body,moderation_status) returning id into message_id;
 if unsafe then insert into public.moderation_cases(subject_type,subject_id,labels,confidence,evidence) values('message',message_id,array['safety_or_sensitive_data'],0.88,jsonb_build_object('detector','rules-id-v1'));end if;
 return message_id;
end;$$;

create or replace function public.publish_tracking_point(p_booking_id uuid,p_latitude double precision,p_longitude double precision,p_accuracy numeric,p_captured_at timestamptz)
returns bigint language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());point_id bigint;b public.bookings;
begin
 select * into b from public.bookings where id=p_booking_id and status in('en_route','in_progress');
 if b.id is null or not private.is_provider_member(b.provider_id,array['owner','dispatcher','technician']) or p_latitude not between -11.5 and 6.5 or p_longitude not between 94 and 142 or p_accuracy<0 or p_accuracy>5000 or p_captured_at>now()+interval '2 minutes' then raise exception 'tracking point denied' using errcode='42501';end if;
 insert into public.tracking_points(booking_id,provider_user_id,location,accuracy_meters,captured_at) values(b.id,actor_id,public.st_setsrid(public.st_makepoint(p_longitude,p_latitude),4326)::public.geography,p_accuracy,p_captured_at) returning id into point_id;
 return point_id;
end;$$;

create or replace function public.resolve_moderation_case(p_case_id uuid,p_decision text,p_reason text,p_correlation_id text)
returns void language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());c public.moderation_cases;
begin
 if not(private.has_platform_role('support') or private.has_platform_role('compliance') or private.has_platform_role('admin') or private.has_platform_role('super_admin')) or coalesce((select auth.jwt()->>'aal'),'')<>'aal2' then raise exception 'moderator AAL2 required' using errcode='42501';end if;
 if p_decision not in('allowed','blocked') or length(trim(p_reason))<10 then raise exception 'reasoned moderation decision required' using errcode='22023';end if;
 select * into c from public.moderation_cases where id=p_case_id and status in('open','appealed') for update;if c.id is null then raise exception 'active moderation case not found' using errcode='P0002';end if;
 update public.moderation_cases set status=p_decision,assigned_to=actor_id,resolution_reason=trim(p_reason),resolved_at=now() where id=c.id;
 if c.subject_type='review' then
  update public.reviews set status=case when p_decision='allowed' then 'published' else 'removed' end,updated_at=now() where id=c.subject_id;
  update public.providers p set rating_avg=(select avg(r.rating)::numeric(3,2) from public.reviews r where r.provider_id=p.id and r.status='published'),rating_count=(select count(*) from public.reviews r where r.provider_id=p.id and r.status='published'),updated_at=now() where p.id=(select provider_id from public.reviews where id=c.subject_id);
 else update public.messages set moderation_status=case when p_decision='allowed' then 'allowed' else 'blocked' end where id=c.subject_id;end if;
 insert into public.audit_logs(actor_user_id,actor_type,action,resource_type,resource_id,reason,correlation_id) values(actor_id,'staff','moderation.'||p_decision,'moderation_case',c.id::text,trim(p_reason),coalesce(nullif(p_correlation_id,''),gen_random_uuid()::text));
end;$$;

create or replace function public.submit_verified_review(p_booking_id uuid,p_rating smallint,p_title text,p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor_id uuid:=(select auth.uid());b public.bookings;new_id uuid;unsafe boolean;
begin
 select * into b from public.bookings where id=p_booking_id and customer_id=actor_id and status in('customer_confirmed','closed','resolved');if b.id is null or p_rating not between 1 and 5 then raise exception 'review not eligible' using errcode='22023';end if;
 unsafe:=lower(coalesce(p_title,'')||' '||coalesce(p_body,'')) ~ '(ancam|bunuh|penipuan|nomor kartu|kata sandi)';
 insert into public.reviews(booking_id,customer_id,provider_id,rating,title,body,status,moderation) values(b.id,actor_id,b.provider_id,p_rating,nullif(trim(p_title),''),nullif(trim(p_body),''),case when unsafe then 'flagged' else 'published' end,jsonb_build_object('detector','rules-id-v1','confidence',case when unsafe then 0.88 else 0.70 end)) returning id into new_id;
 if unsafe then insert into public.moderation_cases(subject_type,subject_id,labels,confidence,evidence) values('review',new_id,array['safety_or_sensitive_data'],0.88,jsonb_build_object('detector','rules-id-v1'));else update public.providers set rating_avg=(select avg(rating)::numeric(3,2) from public.reviews where provider_id=b.provider_id and status='published'),rating_count=(select count(*) from public.reviews where provider_id=b.provider_id and status='published'),updated_at=now() where id=b.provider_id;end if;
 return new_id;
end;$$;

do $$begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='messages') then alter publication supabase_realtime add table public.messages;end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tracking_points') then alter publication supabase_realtime add table public.tracking_points;end if;
end$$;

revoke all on function public.suggest_job_intake(text,uuid),public.send_moderated_message(uuid,uuid,text),public.publish_tracking_point(uuid,double precision,double precision,numeric,timestamptz),public.resolve_moderation_case(uuid,text,text,text) from public;
grant execute on function public.suggest_job_intake(text,uuid),public.send_moderated_message(uuid,uuid,text),public.publish_tracking_point(uuid,double precision,double precision,numeric,timestamptz),public.resolve_moderation_case(uuid,text,text,text) to authenticated;

commit;
