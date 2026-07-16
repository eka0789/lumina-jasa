# Phase 3 Acceptance Record

Status: **transaction pilot implementation complete; sandbox/reconciliation evidence pending CI and staging**.

| Outcome | Repository evidence | Gate |
|---|---|---|
| Manual job intake | `/pesan`, `submit_job_request` | validation, idempotency and matching pgTAP |
| Matching and quote | `/mitra/permintaan`, `/permintaan/[id]`, versioned `job_quotes` | participant RLS and quote test |
| Scheduled booking | transactional quote acceptance and provider time exclusion constraint | conflict/booking database test |
| Sandbox payment | `/pesanan/[id]/bayar`, fail-closed environment switch | capture and amount validation test |
| Financial ledger | append-only triggers and deferred zero-sum constraint | balanced ledger assertion |
| Invoice | immutable invoice number and line snapshots on capture | uniqueness/total database test |
| Workflow | role-aware state-transition RPC and immutable event timeline | positive and negative transition tests |
| Chat/notifications | participant conversation, durable messages and in-app notifications | RLS and booking creation test |

## Financial and workflow controls

- Browser totals are display-only; the booking transaction recomputes fees from the locked quote.
- A provider schedule exclusion constraint rejects overlapping active bookings.
- Sandbox capture defaults to disabled unless the database environment is explicitly non-production. Local `seed.sql` enables it only for the local database.
- Every capture posts signed entries that must sum to zero at commit.
- Ledger transactions and entries cannot be updated or deleted.
- Payment capture creates a hold; customer confirmation releases it.
- Role and current status determine allowed workflow transitions.

## Remaining exit evidence

Before the transaction pilot is accepted, attach a green database CI run plus staging evidence for end-to-end sandbox reconciliation, schedule-conflict behavior, invoice inspection, chat access isolation, and support runbooks. Real PSP webhooks, payout and refund certification remain later payment/trust gates and must not be represented by the sandbox path.
