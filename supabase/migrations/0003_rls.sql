begin;

create or replace function private.has_platform_role(required_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = (select auth.uid()) and r.role = required_role and r.revoked_at is null
  );
$$;

create or replace function private.is_business_member(target_business_id uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.business_members m
    where m.business_id = target_business_id and m.user_id = (select auth.uid()) and m.status = 'active'
      and (allowed_roles is null or m.role = any(allowed_roles))
  );
$$;

create or replace function private.is_provider_member(target_provider_id uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.provider_members m
    where m.provider_id = target_provider_id and m.user_id = (select auth.uid()) and m.status = 'active'
      and (allowed_roles is null or m.role = any(allowed_roles))
  );
$$;

create or replace function private.is_job_customer(target_job_id uuid)
returns boolean language plpgsql stable security definer set search_path = '' as $$
begin
  return exists (
    select 1 from public.jobs j
    where j.id = target_job_id and (j.customer_id = (select auth.uid()) or private.is_business_member(j.business_id, null))
  );
end;
$$;

create or replace function private.is_booking_participant(target_booking_id uuid)
returns boolean language plpgsql stable security definer set search_path = '' as $$
begin
  return exists (
    select 1 from public.bookings b
    where b.id = target_booking_id and (
      b.customer_id = (select auth.uid()) or b.assigned_user_id = (select auth.uid())
      or private.is_business_member(b.business_id, null)
      or private.is_provider_member(b.provider_id, null)
    )
  );
end;
$$;

create or replace function private.is_conversation_participant(target_conversation_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.conversation_participants p
    where p.conversation_id = target_conversation_id
      and p.user_id = (select auth.uid()) and p.left_at is null
  );
$$;

create or replace function private.can_access_file(target_file_id uuid)
returns boolean language plpgsql stable security definer set search_path = '' as $$
begin
  return exists (
    select 1 from public.message_attachments a
    join public.messages m on m.id = a.message_id
    join public.conversation_participants p on p.conversation_id = m.conversation_id
    where a.file_id = target_file_id and p.user_id = (select auth.uid()) and p.left_at is null
  ) or exists (
    select 1 from public.job_media jm join public.jobs j on j.id = jm.job_id
    left join public.bookings b on b.job_id = j.id
    where jm.file_id = target_file_id and (
      j.customer_id = (select auth.uid()) or private.is_business_member(j.business_id,null)
      or (b.id is not null and private.is_provider_member(b.provider_id,null))
    )
  ) or exists (
    select 1 from public.dispute_evidence e join public.disputes d on d.id = e.dispute_id
    where e.file_id = target_file_id and private.is_booking_participant(d.booking_id)
  ) or exists (
    select 1 from public.invoices i where i.file_id = target_file_id and private.is_booking_participant(i.booking_id)
  );
end;
$$;

revoke all on function private.has_platform_role(text) from public;
revoke all on function private.is_business_member(uuid,text[]) from public;
revoke all on function private.is_provider_member(uuid,text[]) from public;
revoke all on function private.is_booking_participant(uuid) from public;
revoke all on function private.is_conversation_participant(uuid) from public;
revoke all on function private.can_access_file(uuid) from public;
grant execute on function private.has_platform_role(text), private.is_business_member(uuid,text[]),
  private.is_provider_member(uuid,text[]), private.is_booking_participant(uuid), private.is_conversation_participant(uuid),
  private.can_access_file(uuid) to authenticated;

do $$
declare t record;
begin
  for t in
    select tablename from pg_tables
    where schemaname = 'public' and tableowner = current_user
  loop
    execute format('alter table public.%I enable row level security', t.tablename);
    execute format('revoke all on table public.%I from anon, authenticated', t.tablename);
  end loop;
end $$;

grant select on public.categories, public.services, public.providers, public.provider_services, public.provider_portfolios, public.reviews to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select on public.user_roles to authenticated;
grant select, insert, update, delete on public.addresses to authenticated;
grant select on public.businesses, public.business_members, public.provider_members to authenticated;
grant select, insert, update on public.jobs, public.bookings to authenticated;
grant select on public.job_matches, public.job_status_events, public.tracking_points to authenticated;
grant select on public.conversations, public.conversation_participants to authenticated;
grant select, insert, update on public.messages, public.message_receipts to authenticated;
grant select, insert on public.message_attachments to authenticated;
grant select, insert, update on public.files to authenticated;
grant select on public.payment_intents, public.payment_holds, public.refunds, public.payouts, public.invoices, public.invoice_lines to authenticated;
grant select, insert, update on public.disputes, public.dispute_evidence to authenticated;
grant select, insert, update on public.reviews to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;
grant select, update on public.notifications to authenticated;
grant select on public.ai_predictions to authenticated;

create policy profiles_own_select on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_own_update on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy roles_own_read on public.user_roles for select to authenticated using (user_id = (select auth.uid()));

create policy addresses_own_all on public.addresses for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy businesses_member_read on public.businesses for select to authenticated
  using (private.is_business_member(id,null));
create policy business_members_member_read on public.business_members for select to authenticated
  using (private.is_business_member(business_id,null));

create policy providers_public_read on public.providers for select to anon, authenticated using (status = 'active' and verification_status = 'verified');
create policy provider_members_member_read on public.provider_members for select to authenticated
  using (private.is_provider_member(provider_id,null));
create policy categories_public_read on public.categories for select to anon, authenticated using (status = 'active');
create policy services_public_read on public.services for select to anon, authenticated using (status = 'active');
create policy provider_services_public_read on public.provider_services for select to anon, authenticated using (
  status = 'active' and exists (select 1 from public.providers p where p.id = provider_services.provider_id and p.status = 'active' and p.verification_status = 'verified')
);
create policy portfolios_public_read on public.provider_portfolios for select to anon, authenticated using (
  status = 'approved' and exists (select 1 from public.providers p where p.id = provider_portfolios.provider_id and p.status = 'active' and p.verification_status = 'verified')
);

create or replace function private.is_job_participant(target_job_id uuid)
returns boolean language plpgsql stable security definer set search_path = '' as $$
begin
  return exists (
    select 1 from public.jobs j where j.id = target_job_id and (
      j.customer_id = (select auth.uid()) or private.is_business_member(j.business_id,null)
    )
  ) or exists (
    select 1 from public.bookings b where b.job_id = target_job_id and private.is_provider_member(b.provider_id,null)
  );
end;
$$;

grant execute on function private.is_job_participant(uuid) to authenticated;

create policy jobs_participant_read on public.jobs for select to authenticated using (
  customer_id = (select auth.uid()) 
  or private.is_business_member(business_id, null)
  or exists (
    select 1 from public.bookings b where b.job_id = id and private.is_provider_member(b.provider_id, null)
  )
);
create policy jobs_customer_insert on public.jobs for insert to authenticated with check (
  customer_id = (select auth.uid()) and (business_id is null or private.is_business_member(business_id,array['owner','admin','requester']))
);
create policy jobs_customer_update on public.jobs for update to authenticated
  using (customer_id = (select auth.uid()) and status in ('draft','requested'))
  with check (customer_id = (select auth.uid()));

create policy bookings_participant_read on public.bookings for select to authenticated using (
  customer_id = (select auth.uid()) 
  or assigned_user_id = (select auth.uid())
  or private.is_business_member(business_id, null)
  or private.is_provider_member(provider_id, null)
);
create policy job_matches_customer_read on public.job_matches for select to authenticated
  using (
    job_id in (select id from public.jobs where customer_id = (select auth.uid()) or private.is_business_member(business_id, null))
  );
create policy status_events_participant_read on public.job_status_events for select to authenticated using (private.is_booking_participant(booking_id));
create policy tracking_participant_read on public.tracking_points for select to authenticated using (private.is_booking_participant(booking_id));

create policy conversations_participant_read on public.conversations for select to authenticated using (
  private.is_conversation_participant(id)
);
create policy participants_participant_read on public.conversation_participants for select to authenticated using (
  private.is_conversation_participant(conversation_id)
);
create policy messages_participant_read on public.messages for select to authenticated using (
  private.is_conversation_participant(conversation_id)
);
create policy messages_participant_insert on public.messages for insert to authenticated with check (
  sender_user_id = (select auth.uid()) and private.is_conversation_participant(conversation_id)
);
create policy receipts_own on public.message_receipts for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy attachments_participant_read on public.message_attachments for select to authenticated using (
  exists (select 1 from public.messages m where m.id = message_attachments.message_id)
);
create policy attachments_sender_insert on public.message_attachments for insert to authenticated with check (
  exists (select 1 from public.messages m where m.id = message_attachments.message_id and m.sender_user_id = (select auth.uid()))
);

create policy files_owner_read on public.files for select to authenticated using (
  owner_user_id = (select auth.uid()) or private.is_business_member(business_id,null) or private.can_access_file(id)
);
create policy files_owner_insert on public.files for insert to authenticated with check (
  owner_user_id = (select auth.uid()) and (business_id is null or private.is_business_member(business_id,null))
);
create policy files_owner_update on public.files for update to authenticated using (owner_user_id = (select auth.uid()));

create policy payment_intents_participant_read on public.payment_intents for select to authenticated using (private.is_booking_participant(booking_id));
create policy holds_participant_read on public.payment_holds for select to authenticated using (private.is_booking_participant(booking_id));
create policy refunds_participant_read on public.refunds for select to authenticated using (private.is_booking_participant(booking_id));
create policy payouts_provider_read on public.payouts for select to authenticated using (private.is_provider_member(provider_id,null));
create policy invoices_participant_read on public.invoices for select to authenticated using (private.is_booking_participant(booking_id));
create policy invoice_lines_participant_read on public.invoice_lines for select to authenticated using (
  exists (select 1 from public.invoices i where i.id = invoice_lines.invoice_id and private.is_booking_participant(i.booking_id))
);

create policy disputes_participant_read on public.disputes for select to authenticated using (private.is_booking_participant(booking_id));
create policy disputes_participant_insert on public.disputes for insert to authenticated with check (opened_by = (select auth.uid()) and private.is_booking_participant(booking_id));
create policy evidence_participant_read on public.dispute_evidence for select to authenticated using (
  exists (select 1 from public.disputes d where d.id = dispute_evidence.dispute_id and private.is_booking_participant(d.booking_id))
);
create policy evidence_participant_insert on public.dispute_evidence for insert to authenticated with check (
  submitted_by = (select auth.uid()) and exists (select 1 from public.disputes d where d.id = dispute_evidence.dispute_id and private.is_booking_participant(d.booking_id))
);

create policy reviews_public_read on public.reviews for select to anon, authenticated using (status = 'published');
create policy reviews_customer_insert on public.reviews for insert to authenticated with check (
  customer_id = (select auth.uid()) and exists (
    select 1 from public.bookings b where b.id = reviews.booking_id and b.customer_id = (select auth.uid())
      and b.provider_id = reviews.provider_id and b.status in ('customer_confirmed','closed')
  )
);
create policy preferences_own on public.notification_preferences for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_own_read on public.notifications for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_own_update on public.notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy ai_predictions_subject_read on public.ai_predictions for select to authenticated using (accepted_by = (select auth.uid()));

-- No client policies are intentionally defined for ledger, payment events, audit,
-- system settings, verification and fraud internals. Use narrowly scoped audited RPCs.

commit;
