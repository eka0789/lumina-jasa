# Delivery Roadmap and Sprint Plan

Estimate assumes a durable team of product manager, designer/researcher, tech lead, 2 frontend, 2 backend/platform, 1 AI/data, 1 QA automation and part-time security/compliance/finance. Dates are planning ranges; discovery, PSP onboarding and legal approval can change the critical path.

## 1. Phases

| Phase | Weeks | Outcomes | Exit criteria |
|---|---:|---|---|
| 0 Discovery/control design | 1–3 | launch market/category, service blueprint, legal/PSP/KYC decisions, threat models, KPI/event taxonomy | decision log and control owners approved |
| 1 Foundation | 4–7 | monorepo, environments, CI, Supabase migrations/RLS, auth/MFA, observability, design tokens | clean deploy/restore, cross-tenant tests green |
| 2 Supply/catalog | 8–11 | provider onboarding, manual KYC/KYB queue, services, areas, availability, public search/profile | 20–50 pilot providers onboarded |
| 3 Transaction pilot | 12–17 | job intake (manual first), matching rules, scheduled booking, payment, ledger, workflow, invoice, basic chat/notifications | end-to-end sandbox reconciliation; support runbooks |
| 4 Trust/business | 18–22 | disputes/refunds, reviews, business membership/approval, staff segregation, privacy workflows | financial/security/UAT gates pass |
| 5 AI/realtime MVP | 23–27 | AI intake/pricing, hybrid ranking/search, realtime signals, tracking, moderation | eval/canary and degraded-mode tests pass |
| 6 Launch hardening | 28–31 | load, accessibility, pentest, restore/game days, PSP certification, analytics, pilot fixes | go-live checklist and executive/legal approval |
| 7 Scale | ongoing | emergency flow, advanced fraud, multichannel notifications, forecasting, learned reranker | quarterly outcome/economic gates |

## 2. First eight two-week sprints

| Sprint | Goal | Selected deliverables |
|---|---|---|
| 0 | Decisions and walking skeleton | ADRs, service blueprint, repo/CI, env validation, health/readiness, telemetry |
| 1 | Identity boundary | Supabase SSR auth, profile trigger, roles/memberships, MFA, RLS harness |
| 2 | Provider supply | provider/profile/listing/category/availability schema, onboarding UI, private file pipeline |
| 3 | Discovery | public catalog/search, geo filter, provider profile, admin category queue |
| 4 | Request and quote | job wizard/manual classification, media, provider candidate rules, quote snapshot |
| 5 | Booking correctness | capacity transaction, state machine, timelines, idempotency and conflict UX |
| 6 | Money path | PSP sandbox, signed webhook inbox, ledger/hold, invoice, reconciliation report |
| 7 | Fulfilment pilot | provider job UI, durable chat, notifications, completion evidence, support workspace |

Each sprint reserves capacity for security/accessibility/test automation and includes production-like telemetry. AI is not on the critical payment path and begins after trustworthy labels/outcomes exist.

## 3. Workstreams

### Product/design

Research with customers/providers/business buyers; content/legal review; responsive prototypes; accessibility; support playbooks; analytics definitions; pilot feedback.

### Backend/platform

Schema/RLS, application commands, outbox/worker, provider adapters, financial ledger/reconciliation, observability, retention and DR automation.

### Frontend

App Router shells, design system, role surfaces, forms, query/realtime integration, offline/degraded states, performance and accessibility.

### AI/data

Event/label quality, baseline rules, evaluation sets, version registry, intake/pricing/ranking, monitoring and safe feedback. Future order: better calibration → learned reranker → demand forecast → anomaly models; generative polish is lower priority than measurable decisions.

### Trust/compliance

Prohibited services, KYC/KYB, privacy basis/consent/retention, PSP/fund-flow wording, dispute policy, staff access, incident/breach process and vendor assessments.

## 4. Dependencies and decision deadlines

| Decision/dependency | Needed by | Owner | Failure mode |
|---|---|---|---|
| Launch city/categories and supply plan | Week 1 | Product/GM | no useful liquidity model |
| PSP/platform account and fund-flow approval | Week 3 | Finance/legal | payment design invalid |
| KYC/liveness vendor and biometric basis | Week 4 | Compliance | provider activation blocked |
| Fee/tax/invoice policy | Week 6 | Finance/legal | quote/ledger snapshot unstable |
| Cancellation/dispute/auto-confirm policy | Week 8 | Product/legal | state/payment ambiguity |
| Notification providers/templates/consent | Week 12 | Ops/legal | unreliable fulfilment comms |
| Production domain/accounts/security ownership | Week 16 | Platform | launch operations blocked |

## 5. Backlog priority

- **P0 pilot:** identity, provider verification, catalog, scheduled booking, state workflow, PSP collection, ledger/hold/release, invoice, basic chat/email/in-app, dispute/refund, admin/support/audit, RLS/monitoring/backup.
- **P1 MVP:** business approvals, AI intake/pricing/ranking, hybrid search, realtime/read receipts, tracking, moderation, push and operational analytics.
- **P2 scale:** emergency dispatch, WhatsApp/SMS, voice notes, advanced fraud, forecasting, provider teams/capacity optimization and native apps.

## 6. Launch checklist

- P0 acceptance and UAT with real pilot roles.
- Legal/compliance approve terms, privacy, consent, prohibited services, payment wording, retention and dispute policy.
- PSP/KYC production onboarding and webhook certification complete.
- RLS/permissions, pentest, accessibility and load gates pass with no critical/high issue.
- Ledger/provider daily reconciliation and payout/refund dual control proven.
- Monitoring/on-call/status communications and SEV runbooks exercised.
- PITR/backups configured and isolated restore meets RPO/RTO.
- Kill switches exist for AI, tracking, booking intake and payout release.
- Staged launch: internal → invited providers/customers → city/category cohort → wider traffic.

## 7. Delivery metrics

Track lead time, deployment frequency, change failure rate, MTTR, escaped defect severity, flaky test rate, migration rollback/forward-fix incidents and security remediation age. Product delivery is accepted by customer/provider outcomes and financial correctness, not story count.
