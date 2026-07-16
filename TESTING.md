# Testing and Quality Strategy

Quality is risk-based: financial correctness, authorization, tenant isolation and state transitions receive deeper tests than cosmetic behavior.

## 1. Test layers

| Layer | Tools/examples | Gate |
|---|---|---|
| Static | TypeScript strict, ESLint, formatting, Zod/OpenAPI generation, secret/SCA scan | every PR |
| Unit | Vitest: value objects, pricing/fees, transitions, permissions, ranking | every PR |
| Database | pgTAP/SQL: constraints, RPCs, RLS positive and negative cases | every PR |
| Integration | Next Route Handlers + local Supabase + vendor adapters | every PR |
| Contract | OpenAPI schema, PSP/KYC/notification webhook fixtures | every PR/nightly |
| Component | Testing Library, axe, keyboard behavior | every PR |
| E2E | Playwright critical journeys by role | merge/deploy gate |
| Performance | k6 API/webhook/tracking/chat and browser Lighthouse/RUM | staging/release |
| Security | SAST, DAST, dependency/secret/config scan, pentest | continuous/release |
| Resilience | timeout, duplicate/out-of-order webhook, worker crash, vendor outage | staging/release |
| AI | golden/adversarial sets, calibration, fairness, latency/cost | model release |

No test uses production credentials or unrestricted production data. Deterministic factories produce users/tenants/providers/bookings and a fake clock controls time windows.

## 2. Critical scenario matrix

### Authorization/RLS

- Customer A cannot infer/read/update Customer B’s job by UUID, list query, nested relation, Realtime or signed file URL.
- Business requester can create in Business A but cannot approve above permission/limit or access Business B.
- Provider worker sees assigned/provider-scope jobs but cannot change payout or company owner settings.
- Support/finance/compliance each see only permitted masked views; revoked membership takes effect on sensitive command.
- Anon sees only active/approved public fields. Service keys are absent from browser bundles.

### Booking/concurrency

- Two simultaneous bookings for final capacity produce one success and one deterministic conflict.
- Every actor/state/action combination is tested; invalid transition leaves no partial records.
- Retry with same idempotency key returns the same outcome; different payload returns conflict.
- Stale version returns `409` and no lost update.

### Payment/ledger

- Valid, invalid, replayed, out-of-order and delayed webhooks.
- Provider reference correct but amount/currency/account wrong → exception, no capture posting.
- Every scenario balances: capture, fee, hold, partial release, full release, partial refund, payout, failed/reversed payout.
- Dispute/release race cannot over-release. Requester cannot approve own controlled refund.
- Daily reconciliation detects missing, duplicate and unexpected provider events.

### Files/chat/location

- MIME spoof, oversized file, malware result, abandoned upload, expired signed URL and cross-tenant object path.
- Message retry/deduplication, order, deletion tombstone, moderation/report and reconnect gap fill.
- Tracking is rejected before/after active window, from unassigned provider, or without consent; stale fallback works.

### Privacy

- Export contains authorized user data and no other tenant.
- Deletion de-identifies eligible records while preserving legally required ledger/invoice data.
- Retention respects legal hold and emits auditable result.
- Logs/traces/errors contain no tokens, raw documents, message bodies or exact coordinates.

## 3. AI testing

Datasets are versioned by module, category, region and language. Include normal, sparse, ambiguous, unsafe, adversarial and prompt-injection cases. Human-labeled gold sets must have annotation instructions and agreement measurement.

- Strict schema validity must be effectively 100% after retry/fallback.
- Intake: top-k category, field F1 and confidence reliability.
- Pricing: interval coverage and width by category/region, not average error alone.
- Ranking: offline relevance plus new-provider exposure and cohort guardrails.
- Fraud/moderation: threshold precision, false positive and appeal-overturn rates.
- Generated insights cite metric IDs and never fabricate inaccessible metrics.

Model releases shadow production traffic using minimized/redacted inputs where lawful, then canary behind a feature flag. Rollback changes model/prompt registry without redeploying the application.

## 4. Performance profiles

Baseline launch test (revise after pilot telemetry): 1,000 concurrent sessions; 50 application commands/s; 20 tracking updates/s; 100 chat messages/s; webhook burst of 10× normal for five minutes. Test steady, spike, soak and recovery. Seed realistic data distributions, RLS and indexes.

Pass criteria: no lost/duplicate financial effects, ordinary API p95 ≤400 ms, error rate <1% excluding injected faults, acceptable DB CPU/connections/lock waits, outbox drains within SLO after burst and no unbounded memory/queue growth.

## 5. Test environments and release gate

- PR: ephemeral/local Supabase, fake vendors, migrations from empty, unit/integration/RLS.
- Staging: production-like separate accounts, vendor sandboxes, synthetic identities/payments only.
- Production: smoke tests are read-only or dedicated synthetic tenant; no destructive test.

Release requires green migrations/types, RLS suite, critical E2E, contract tests, accessibility critical-flow check, performance evidence for material changes, zero critical/high security findings, approved rollback/forward-fix and owner sign-off. Flaky tests are quarantined only with owner and expiry; critical flow tests cannot be waived silently.
