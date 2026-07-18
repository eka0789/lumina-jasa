# 11 — In-App Chat Feature Audit

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** PASS

---

## 1. Technical Architecture & Realtime sync

The chat module facilitates communications between customers and providers. It uses Next.js client components connected to a Supabase Postgres Replication publication.

### Messaging Architecture
- **Realtime sync:** The `booking-chat.tsx` component subscribes to the `messages` table via Supabase Realtime using a filter:
  `conversation_id=eq.${conversationId}`
  This configuration limits client-side updates to changes in the active chat.
- **Message Dispatch:** Messages are sent using the `send_moderated_message` database function. It validates sender access, applies spam/safety filters, writes the message record, and returns the message UUID.
- **Fallback Execution:** If a client's websocket connection is degraded, the client falls back to manual page refresh, retrieving past messages via server-side rendering (SSR) in `pesanan/[id]/page.tsx`.

---

## 2. Security Boundaries & Verification Checks

Message delivery is secured using multiple logic checks:

### 1. Membership Verification
A user can only read or write messages if they are an active participant in the conversation:
```sql
not exists(
  select 1 from public.conversation_participants 
  where conversation_id = p_conversation_id and user_id = actor_id and left_at is null
)
```
This query ensures that users cannot read or inject messages into arbitrary conversations.

### 2. Message Size Constraints
To prevent database bloating and denial-of-service attempts:
- Minimum length: 1 character (excludes empty/whitespace messages).
- Maximum length: 4,000 characters.

---

## 3. Data Integrity & Realtime Replication

- **Replication Setup:** Realtime updates are managed by a publication in `0008_ai_realtime_mvp.sql`:
  ```sql
  alter publication supabase_realtime add table public.messages;
  ```
- **Safety Redactions:** Content flagged by the Indonesian safety regex is redacted with a warning string. The original message is logged in `moderation_cases` for support team review, protecting platform users from phishing or abuse.
