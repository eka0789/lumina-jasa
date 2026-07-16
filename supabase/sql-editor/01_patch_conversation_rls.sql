-- Recovery for an installed schema whose conversation_participants policy
-- recursively queries the same RLS-protected table.
-- Run once, then rerun 02_demo_seed.sql from the beginning.

begin;

create or replace function private.is_conversation_participant(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_participants p
    where p.conversation_id = target_conversation_id
      and p.user_id = (select auth.uid())
      and p.left_at is null
  );
$$;

revoke all on function private.is_conversation_participant(uuid) from public;
grant execute on function private.is_conversation_participant(uuid) to authenticated;

drop policy if exists conversations_participant_read on public.conversations;
drop policy if exists participants_participant_read on public.conversation_participants;
drop policy if exists messages_participant_read on public.messages;
drop policy if exists messages_participant_insert on public.messages;

create policy conversations_participant_read
on public.conversations for select to authenticated
using (private.is_conversation_participant(id));

create policy participants_participant_read
on public.conversation_participants for select to authenticated
using (private.is_conversation_participant(conversation_id));

create policy messages_participant_read
on public.messages for select to authenticated
using (private.is_conversation_participant(conversation_id));

create policy messages_participant_insert
on public.messages for insert to authenticated
with check (
  sender_user_id = (select auth.uid())
  and private.is_conversation_participant(conversation_id)
);

commit;

select policyname,qual,with_check
from pg_policies
where schemaname='public'
  and tablename in ('conversations','conversation_participants','messages')
  and policyname in (
    'conversations_participant_read','participants_participant_read',
    'messages_participant_read','messages_participant_insert'
  )
order by tablename,policyname;
