# 04 — RLS & Authorization Matrix

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** PASS

---

## 1. Role Definitions

Access boundaries are mapped across four distinct user roles defined in the application:

1. **Anonymous / Guest (`anon`)**
   - Public web visitors browsing the directory.
   - Restricted to reading active/verified provider metadata, active categories, and active services.

2. **Authenticated Customer (`authenticated`)**
   - Individual customers requesting tasks.
   - Restricted to reading their own profile, addresses, jobs, and quotes submitted for their jobs.
   - Allowed to interact via chat and tracking for their active bookings.

3. **Authenticated Provider Member / Owner (`authenticated` with member status)**
   - Service providers (owners, managers, technicians).
   - Restricted to reading their own provider entity data, listing services, managing availability, and updating bookings assigned to them.
   - Allowed to interact via chat and publish tracking points during active delivery windows.

4. **Internal Staff / Administrative Roles**
   - Operational groups assigned specific admin roles (e.g. `'support'`, `'compliance'`, `'finance'`, `'admin'`).
   - Allowed reading across transaction history, fraud logs, moderation queues, and managing platform controls.
   - Sensitive actions require Multi-Factor Authentication (MFA) AAL2 level validation.

---

## 2. Row Level Security Authorization Matrix

| Table | Anon (`SELECT`) | Customer (`SELECT`) | Customer (`INSERT/UPDATE`) | Provider (`SELECT`) | Provider (`INSERT/UPDATE`) | Staff / Support (`SELECT`) | Staff (`INSERT/UPDATE`) |
|---|---|---|---|---|---|---|---|
| **profiles** | Denied | Own row | Own row (Update only) | Own row | Own row (Update only) | Denied (Read via RPC) | Denied |
| **user_roles** | Denied | Own roles | Denied | Own roles | Denied | Denied | Denied (Managed via RPC) |
| **addresses** | Denied | Own address | Own address | Own address (if booked) | Denied | Denied | Denied |
| **businesses** | Denied | Member | Member (via RPC) | Denied | Denied | Denied | Denied |
| **business_members** | Denied | Member | Member (via RPC) | Denied | Denied | Denied | Denied |
| **providers** | Active + Verified | Member | Denied | Member | Owner/Manager (Update) | All rows | All rows (via RPC) |
| **provider_members**| Denied | Denied | Denied | Member | Denied | Denied | Denied |
| **categories** | Active only | Active only | Denied | Active only | Denied | Active only | Denied (Managed via seed) |
| **services** | Active only | Active only | Denied | Active only | Denied | Active only | Denied (Managed via seed) |
| **provider_services**| Active only | Active only | Denied | Member | Member (All actions) | Active only | Denied |
| **files** | Denied | Own + Accessible | Own (Insert only) | Own + Accessible | Own (Insert only) | All rows | Denied |
| **jobs** | Denied | Own jobs | Create (Insert/Update) | Matched jobs | Denied | Denied (Managed via RPC) | Denied |
| **job_matches** | Denied | Own job matches| Denied | Own job matches | Denied | Denied | Denied |
| **bookings** | Denied | Own bookings | Denied (via RPC) | Member bookings | Denied (via RPC) | Denied (Read via RPC) | Denied |
| **job_status_events**| Denied | Participant | Denied | Participant | Denied | Denied | Denied |
| **tracking_points** | Denied | Participant | Denied | Participant | Insert (via RPC) | Denied | Denied |
| **conversations** | Denied | Participant | Denied | Participant | Denied | Denied | Denied |
| **messages** | Denied | Participant | Insert | Participant | Insert | Denied | Denied (Managed via RPC) |
| **payment_intents** | Denied | Participant | Denied | Participant | Denied | Denied | Denied |
| **payment_holds** | Denied | Participant | Denied | Participant | Denied | Denied | Denied |
| **refunds** | Denied | Participant | Denied | Participant | Denied | All rows | Denied (Managed via RPC) |
| **payouts** | Denied | Denied | Denied | Provider payouts | Denied | Denied | Denied |
| **invoices** | Denied | Participant | Denied | Participant | Denied | Denied | Denied |
| **disputes** | Denied | Participant | Insert | Participant | Insert | All rows | Denied (Managed via RPC) |
| **reviews** | Published only | Participant | Insert | Participant | Denied | Published only | Denied (Managed via RPC) |

---

## 3. Analysis of Cross-Tenant Leakage Prevention

### Multi-Tenant Isolation (Businesses & Providers)
Cross-tenant isolation is secured through RLS policies that validate membership using private helper functions.
For example, row isolation on the `businesses` table is controlled by:
```sql
create policy businesses_member_read on public.businesses for select to authenticated
  using (private.is_business_member(id, null));
```
Because `is_business_member` checks `business_members` table for an active row matching `auth.uid()`, a user from Business A can never retrieve rows belonging to Business B, even if they guess the UUID. The query simply returns zero rows.

### Booking & Chat Participant Safeguards
Message access policies use the same principle:
```sql
create policy messages_participant_read on public.messages for select to authenticated using (
  private.is_conversation_participant(conversation_id)
);
```
Since the `is_conversation_participant` helper function checks if the user is actively listed in `conversation_participants` and hasn't left the room (`left_at is null`), it prevents arbitrary logged-in users from reading messages in private chats.

### Fail-Closed Action Policies
For high-risk operational tables (like `ledger_entries`, `ledger_transactions`, `platform_feature_flags`, and `audit_logs`), no insert, update, or delete policies are defined. Any direct DML (Data Manipulation Language) statement issued by client SDKs will automatically be blocked by PostgreSQL. These tables can only be written to by security definer functions executing as superuser (`postgres` role), ensuring all mutations are structured and fully verified.
