# 03 — Database Schema & RLS Audit

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** PASS

---

## 1. Schema Design & Constraints

Lumina Jasa uses a robust multi-tenant PostgreSQL schema deployed on Supabase. It uses standard relational constraints (Primary Keys, Foreign Keys, unique indexes) to prevent data corruption and enforce business logic at the database layer.

### Core Domain Tables
- `profiles`: Extends Supabase auth.users. Foreign key on `auth.users(id) on delete cascade` ensures automatic cleanup of user records if deleted. Checks enforce `status` constraints ('active', 'suspended', 'deleted') and rating/trust bounds.
- `jobs`: Stores requested work. Uses `requested_start` and `requested_end` to define the execution window.
- `bookings`: Tracks scheduled service delivery, total amount, and fees. Enforces `total_amount = subtotal + platform_fee + tax_amount` constraint.
- `job_quotes`: Bids submitted by service providers for specific job requests. Enforces unique constraint per `(job_id, provider_id, version)` to ensure only one active version exists per provider for a given job.

### Financial / Escrow Architecture
The financial schema is designed to be fully audit-resilient, using a double-entry ledger to track funds, along with explicit holds and refunds.
- `ledger_accounts`: Organizes asset, liability, clearing, revenue, and expense accounts. It maps ownership to `platform`, `customer`, `provider`, `psp`, or `tax` entities.
- `ledger_transactions` & `ledger_entries`: Stores double-entry bookkeeping ledgers.
- `payment_holds`: Enforces delayed payout release. When a booking is confirmed, funds are held (status `'held'`) and only transitioned to `'released'` upon customer confirmation or manual resolution.

---

## 2. RLS & SQL Definer Functions

### The "Fail-Closed" Core Principle
The system implements a zero-trust model at the database level. For every single table created in migrations, the following script block is executed:
```sql
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
```
This script guarantees:
1. **Row Level Security is explicitly enabled** on all public tables.
2. **All default table-level permissions (SELECT, INSERT, UPDATE, DELETE) are revoked** from public roles (`anon` and `authenticated`). Under PostgreSQL RLS rules, if a role has no permissions granted and no policy defined, all access requests are denied (fails closed).
3. Selective `GRANT` statements are subsequently declared to allow authenticated users to perform operations on specific tables.

### Security Definer Helper Functions
All access validation helper functions reside in the `private` schema. These functions are declared as `security definer` to bypass RLS checks on lookup tables, but they strictly set the `search_path` to avoid search-path hijacking attacks:
```sql
create or replace function private.is_provider_member(target_provider_id uuid, allowed_roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.provider_members m
    where m.provider_id = target_provider_id and m.user_id = (select auth.uid()) and m.status = 'active'
      and (allowed_roles is null or m.role = any(allowed_roles))
  );
$$;
```
These functions are secured by revoking execution permissions from the public role and granting them only to the authenticated role:
```sql
revoke all on function private.is_provider_member(uuid,text[]) from public;
grant execute on function private.is_provider_member(uuid,text[]) to authenticated;
```

---

## 3. Database Triggers & Business Rules

Critical transactions are governed by database triggers that enforce immutability, data balance, and feature availability:

### 1. Immutability of Ledger (`ledger_transactions_append_only`)
Ledger records are strictly append-only. The trigger `ledger_transactions_append_only` calls `private.reject_ledger_mutation()` before any update or delete operation on `ledger_transactions` and `ledger_entries`, raising an exception if attempted.

### 2. Double-Entry Balance Verification (`ledger_transaction_balanced`)
A constraint trigger `ledger_transaction_balanced` runs after any modification to `ledger_entries` (insert, update, delete). It is marked as `deferrable initially deferred` to run at commit time, ensuring that the sum of entry amounts for a transaction is exactly `0` (balanced transaction).

### 3. Exclusivity of Provider Schedules (`bookings_provider_time_excl`)
To prevent a provider from being booked for double-booked time slots, a exclusion constraint is declared on `bookings` utilizing the `btree_gist` extension:
```sql
alter table public.bookings add constraint bookings_provider_time_excl
  exclude using gist (provider_id with =, tstzrange(scheduled_start, scheduled_end, '[)') with &&)
  where (status <> 'cancelled');
```
This ensures no overlapping scheduled booking intervals can exist for the same active provider.

### 4. Feature Flag Controls (`require_feature_enabled`)
Triggers are defined on table inserts/updates to block action requests if the respective feature flag is disabled:
- `guard_booking_intake`: Blocks job posting when the `booking_intake` flag is off.
- `guard_payment_capture`: Blocks payment captures when the `payment_capture` flag is off.
- `guard_payout_release`: Blocks payout releases when the `payout_release` flag is off.

---

## 4. Performance & Scalability (Indexes)

To support spatial lookup and rapid search under load, indexes are declared on key access patterns:
- **Spatial Indexing:** GIST index on service area polygons:
  `create index provider_area_gist on public.provider_service_areas using gist(area);`
- **Vector Search Indexing:** Designed for provider ranking / matchmaking. Column `embedding` is declared on `provider_services` as a `vector(1536)` (for OpenAI text-embedding-3-small or equivalent standard model representations).
- **Relational Indexes:** Explicit indexing on join-heavy foreign keys (e.g. `addresses(user_id)`, `bookings(provider_id, scheduled_start)`, and `ledger_entries(transaction_id)`).
- **Partial Indexes:** Optimize common queries (e.g., `jobs(business_id)` indexed only when `business_id` is not null, `outbox_events` indexed on `available_at` only when `published_at` is null).
