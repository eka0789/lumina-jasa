# Product Requirements Document — Lumina Jasa

**Status:** baseline for discovery and estimation  
**Market:** Indonesia; B2C, B2B and service providers  
**Principle:** AI reduces effort and uncertainty; it never silently removes user agency or determines high-impact outcomes alone.

## 1. Vision and problem

Customers struggle to describe service needs, assess provider quality, compare price and recover from poor outcomes. Providers struggle to build trust, find qualified demand, schedule work and receive predictable payment. Business buyers additionally need approvals, invoices, auditability and multi-user procurement.

Lumina Jasa is a trusted procurement workflow: describe a need, obtain an explainable estimate, choose a verified provider, transact through a controlled payment workflow, communicate and track work, confirm evidence and resolve exceptions.

## 2. Goals and non-goals

### Goals

- Match a service request to at least three eligible providers quickly in launch zones.
- Make quote assumptions, fees, provider credentials and job state transparent.
- Protect both sides with verified identities, payment controls, evidence and disputes.
- Give providers scheduling, catalog, job and earnings tools.
- Give businesses membership, approval, invoice and reporting controls.
- Make every privileged, financial and AI-assisted decision traceable.

### Non-goals for MVP

- Native mobile apps, cross-border/cross-currency settlement, lending, insurance, payroll, open bidding, autonomous fraud bans, fully automated dispute judgments, and a general-purpose social network.
- Holding customer funds outside capabilities and contracts approved by the selected licensed PSP and counsel.

## 3. Personas and jobs to be done

| Persona | Need | Success signal |
|---|---|---|
| Household customer | “Help me identify and fix this problem safely.” | Confident choice, predictable total, verified completion |
| SME requester | “Procure a service with company records and approval.” | Controlled spend, invoice, audit trail |
| Business approver | “Approve exceptions without slowing routine work.” | Policy-based queue and complete evidence |
| Individual provider | “Find suitable work and get paid reliably.” | Qualified leads, low idle time, clear payout |
| Provider company | “Coordinate staff, service areas and schedules.” | Utilization and performance visibility |
| Support agent | “Resolve a case from one timeline.” | Low handling time, reproducible decision |
| Compliance/finance | “Review risk and money without excess access.” | Segregated permissions and reconciled records |

## 4. Roles

Roles are capabilities, not a single mutable `role` column. A person may be a customer, provider and business member simultaneously.

| Role | Core capabilities |
|---|---|
| Guest | Browse approved public catalog/provider summaries |
| Customer | Manage own requests, bookings, payments, chats and reviews |
| Business member | Act within assigned business role and spend policy |
| Provider owner/manager/worker | Manage provider scope, availability and assigned jobs |
| Support | Read support scope, create case notes; no arbitrary payout |
| Finance | Reconcile, approve controlled refunds/payouts; no KYC media by default |
| Compliance | Review KYC/KYB/risk; no ledger mutation |
| AI moderator | Review flagged content; no identity or payment decisions |
| Admin | Operate catalog and users within explicit grants |
| Super admin | Break-glass operations with MFA, reason and alerting |

## 5. End-to-end journeys

### Customer booking

1. Enter natural-language need, location, schedule and optional media.
2. AI suggests category, missing questions, price/duration range and confidence; customer confirms.
3. System filters ineligible providers and ranks eligible matches with reasons.
4. Customer selects a listing/provider, reviews fees and cancellation terms, then authorizes payment.
5. Provider accepts, travels, checks in, performs work and uploads completion evidence.
6. Customer confirms or disputes; eligible funds are released under configured rules.
7. Invoice/receipt is issued and both sides may provide feedback.

### Business booking

Same flow plus cost center, purchase reference, member permissions and approval when thresholds/policies require it.

### Provider onboarding

Create profile, accept consent, submit identity/business and payout information, pass automated checks, complete manual review when needed, configure services/areas/availability, then publish after approval.

### Dispute

An eligible participant selects a reason, amount and evidence. Release is blocked for the disputed amount. Support sees an immutable timeline, communicates with both parties, records a reasoned resolution and triggers refund/release through a segregated approval flow. Appeals are supported.

## 6. Product capabilities and acceptance outcomes

| Capability | MVP outcome |
|---|---|
| Authentication | Email, Google and phone OTP; session/device management; staff MFA |
| Identity/trust | KYC/KYB state, OCR/liveness vendor integration, manual review, consent and retention |
| Catalog | Hierarchical categories, provider listings, service areas, portfolios and search |
| AI intake | Structured request draft with assumptions, confidence and editable fields |
| Pricing | Range, inclusions/exclusions, evidence, confidence; never a guaranteed quote unless provider accepts |
| Matchmaking | Eligibility filters, ranked candidates, reason codes, diversity and manual browse fallback |
| Booking | Instant, scheduled and emergency modes; inventory hold; cancellation policy snapshot |
| Job workflow | Validated transition machine, actor/timestamp/evidence history, offline-tolerant actions |
| Payments | Provider checkout, verified webhooks, ledger, hold/release, refunds, payouts and reconciliation |
| Tracking | Consent-based active-job GPS, ETA, last update and automatic expiry |
| Chat | Durable text/media/voice metadata, typing/read signals, reporting and optional translation |
| Reviews | One verified review per completed job, media, provider response, moderation and appeal |
| Business | Membership, requester/approver/admin roles, cost centers, approval rules and reporting |
| Operations | Support, finance, compliance and admin work queues with least privilege and audit |
| Analytics | Governed event taxonomy, marketplace funnel, SLA, risk and financial metrics |

## 7. Policies that must be configurable

- Platform fee, tax treatment, emergency surcharge and provider payout delay.
- Booking cancellation windows and fee schedule snapshotted at confirmation.
- Auto-confirm timeout by category and risk tier.
- Dispute window, evidence requirements, refund approval threshold and dual control.
- Provider eligibility thresholds, service radius and concurrent capacity.
- AI confidence thresholds and manual fallback.
- Location, message, KYC, invoice and audit retention.

Configuration changes are versioned, effective-dated and audited; existing bookings retain their policy snapshot.

## 8. Success metrics and guardrails

| Area | Primary metric | Guardrail |
|---|---|---|
| Liquidity | qualified requests with ≥3 eligible matches | geographic/provider concentration |
| Conversion | confirmed bookings / qualified requests | cancellation and payment failure |
| Fulfilment | closed without dispute / accepted | late arrival and reassignment |
| Trust | verified completion CSAT | dispute, refund and safety incident rates |
| Provider value | earnings per active hour | acceptance, churn and payout latency |
| AI intake | confirmed fields without manual correction | low-confidence rate by category/language |
| Ranking | booking/completion among impressions | exposure fairness and new-provider coverage |
| Pricing | actual inside predicted interval | interval width and dispute correlation |
| Finance | daily ledger-to-provider reconciliation | unexplained variance must be zero |

No arbitrary year-one GMV target is binding until launch geography, category supply and acquisition budget are approved.

## 9. Release slices

- **Pilot:** auth, provider onboarding/manual verification, catalog, scheduled booking, fixed/provider quote, payment collection, job states, basic chat, invoices, manual support/refunds.
- **MVP:** AI intake, interpretable ranking, price range, realtime signals, business membership/approval, review moderation and automated reconciliation.
- **Scale:** emergency dispatch, live tracking, advanced fraud signals, WhatsApp/SMS routing, forecasting and learned reranking.

## 10. Key risks

| Risk | Mitigation |
|---|---|
| Insufficient local liquidity | Launch one city/category cluster; recruit supply before demand campaign |
| AI overconfidence | Confidence/assumptions, calibrated intervals, editable drafts and fallbacks |
| Funds/escrow misrepresentation | PSP/legal review, precise customer wording, ledger and reconciliation |
| Provider/customer fraud | Progressive limits, KYC, device/payment signals, human review and appeals |
| Staff over-access | Segregated roles, masked views, JIT/break-glass access and audits |
| Vendor outage | Durable queues, circuit breakers, degraded manual workflows |

## 11. Open product decisions

Before Sprint 1, owners must approve launch city/categories, marketplace fee/tax model, PSP, definition of “emergency,” provider employment/agency position, verification vendor, dispute/auto-confirm policy, support hours, data retention and prohibited services policy.
