# Deployment, CI/CD, Observability, Scalability and Recovery

## 1. Environments

Use separate Vercel projects, Supabase projects and vendor accounts for development, staging and production. Production restricted data never enters lower environments. Environment variables are schema-validated at startup; secrets live in provider secret stores and are rotated.

| Environment | Data | Integrations | Access |
|---|---|---|---|
| Local/PR | factories/seed | mocks or sandbox | developers |
| Staging | synthetic production-shape | vendor sandbox | team/UAT |
| Production | real | live accounts | least privilege + MFA |

## 2. CI pipeline

On every PR:

1. Install with locked dependencies; verify provenance and license policy.
2. Secret scan, lint, formatting, TypeScript strict and unit/component tests.
3. Start clean local Supabase; apply every migration and seed.
4. Run database constraint/RLS, integration and OpenAPI contract tests.
5. Generate database types/OpenAPI and fail on committed drift.
6. Build Next.js with production flags; scan client bundle for secret/server-only imports.
7. SCA/SAST/config scan and Playwright critical subset/axe.
8. Produce immutable artifact and preview deployment with no production credentials.

Protected main requires review from code owner; SQL/RLS/payment changes require backend/security/finance-aware review. CI jobs use OIDC/short-lived credentials where supported.

## 3. CD and migration

- Main deploys automatically to staging. Run smoke, contract, migration and synthetic payment tests.
- Production promotion is the tested artifact, with approval for schema/payment/security changes.
- Apply backward-compatible database expansion before application rollout. Backfill in bounded resumable jobs, switch reads/writes behind a flag, and contract later.
- Vercel deployment uses gradual traffic/canary for high-risk releases. Feature flags separate deploy from release.
- Rollback application instantly when schema remains compatible. Database migrations use forward-fix by default; destructive rollback uses restored rehearsal and explicit approval.
- Post-deploy verifies auth, catalog, create-draft, worker, webhook receipt, metrics and error budget.

## 4. Observability

Instrument OpenTelemetry-compatible traces across Next.js, Edge Functions, worker, database calls and vendors. Use Sentry (or equivalent) for exceptions/performance and a durable log/metric backend.

### Golden signals and business controls

| Signal | Examples |
|---|---|
| Traffic | route/command rate, active Realtime connections, tracking updates |
| Errors | error code/rate, vendor failure, schema rejection, webhook signature failure |
| Latency | API/DB/vendor/AI p50/p95/p99, worker queue age |
| Saturation | DB CPU/connections/locks/storage, function concurrency, queue depth |
| Money | capture/release/refund/payout counts, reconciliation variance, stuck holds |
| Marketplace | match coverage, booking conversion, acceptance, completion, disputes |
| AI | fallback/schema failure, confidence drift, latency, tokens/cost, quality samples |

Every request/event has correlation ID, principal/tenant identifiers only when lawful and pseudonymized, deployment version and route/event name. Redact tokens, cookies, authorization, documents, chats, coordinates, bank/payment identifiers and arbitrary request bodies.

### Initial SLOs

- Booking/payment-confirmation availability 99.9% monthly.
- Ordinary application API p95 ≤400 ms; separate AI/vendor SLO.
- Payment webhook durable receipt p95 ≤2 s; processing p95 ≤60 s.
- Notification critical-event enqueue p95 ≤5 s; channel delivery is vendor-specific.
- Outbox oldest-ready age ≤60 s normally; reconciliation completed daily.

Page on symptoms and control failures, not every exception. Alert examples: unexplained reconciliation variance (immediate), webhook failures/signature spike, payout failure spike, queue age, DB connection saturation, cross-tenant/security signal, error-budget burn and backup/retention job failure.

## 5. Scalability

- Next.js/Vercel scales stateless web traffic. Avoid per-instance state and unbounded response bodies.
- Use Supabase transaction pooler/serverless-friendly connections and cap concurrency before DB exhaustion.
- Add composite/partial indexes from measured query plans; cursor paginate; bound every query.
- Cache public catalog at CDN with tagged invalidation. Never publicly cache personalized/financial/location data.
- Batch location UI writes/reads and retain detailed points briefly. Realtime topics are private and scoped.
- Workers lease outbox rows using `FOR UPDATE SKIP LOCKED`, use bounded concurrency and DLQ after retry budget.
- Partition only high-volume append tables (tracking, activity, audit, payment events) after volume evidence and retention requirements.
- Read replicas/materialized projections may serve analytics; transactional commands stay on primary.

Scale stages: optimize/index → cache/projection → increase managed capacity → isolate worker/analytics workloads → extract a bounded module only when team/SLO evidence justifies it.

## 6. Backup and disaster recovery

- Enable Supabase paid-plan PITR appropriate to RPO plus managed daily backups; confirm actual plan/retention before launch.
- Export encrypted logical backups/config and critical bucket inventory to a separate controlled account/region where contracts permit.
- Version migrations, Edge Functions, infrastructure config and notification templates in Git. Back up vendor configuration references and secret-recovery procedures, never plaintext secrets.
- Quarterly restore into an isolated project, run checksums/counts, ledger balance/reconciliation, RLS tests and critical E2E; record achieved RPO/RTO.

### Recovery order

1. Declare incident, stop unsafe writes/payouts and preserve evidence.
2. Establish clean control plane and rotate compromised credentials if applicable.
3. Restore database to approved point; restore/verify storage references.
4. Deploy matching application/functions/workers with outbound side effects disabled.
5. Run integrity/RLS/ledger checks; reconcile PSP events since restore point.
6. Re-enable reads, then bookings/payments, then payouts/notifications in controlled stages.
7. Communicate status, monitor and complete post-incident review.

Targets: tier-1 transactional RPO ≤15 min, RTO ≤2 h. Vendor account compromise, widespread region failure and storage restore may need separate tested scenarios.

## 7. Runbooks

Maintain concise, executable runbooks for payment webhook backlog, reconciliation variance, payout failure, DB saturation, auth outage, Realtime outage, AI/vendor outage, KYC outage, leaked credential, restricted-data incident, abusive user/safety incident, failed migration and restore. Each includes detection, impact, safe first actions, owners, evidence queries, customer communications, rollback/recovery and escalation.

## 8. Scheduled operations

| Cadence | Job/control |
|---|---|
| Continuous | outbox dispatch, notification retry, scan results, AI jobs |
| Hourly | stale booking/payment/verification timeout, queue health |
| Daily | PSP/ledger/payout reconciliation, invoice checks, backup status |
| Weekly | access anomaly, failed retention, cost and model drift review |
| Monthly | staff/vendor access review, dependency/security patch review, SLO/FinOps |
| Quarterly | restore/game day, threat/risk review, retention sample, capacity plan |

Supabase documents managed daily backups and paid-plan point-in-time recovery; validate the selected plan and rehearse restores rather than treating backup presence as recovery proof: [Supabase database overview](https://supabase.com/docs/guides/database/overview).
