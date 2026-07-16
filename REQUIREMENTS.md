# Requirements and Traceability

`P0` blocks pilot/launch; `P1` follows after stable core; `P2` is future. Every requirement needs linked design, implementation, test and owner in the delivery tracker.

## Functional requirements

| ID | Pri | Requirement | Acceptance evidence |
|---|---:|---|---|
| IAM-01 | P0 | Email, Google and phone OTP authentication | Auth E2E tests and provider configuration |
| IAM-02 | P0 | A user may hold multiple platform/tenant roles | Permission matrix tests; no destructive role replacement |
| IAM-03 | P0 | Staff uses MFA; super-admin actions require recent MFA | AAL policy and negative tests |
| IAM-04 | P0 | Session/device listing and revocation | Revoked token cannot access protected resource |
| ORG-01 | P0 | Businesses have members with owner/admin/requester/approver/viewer roles | Cross-tenant RLS suite |
| ORG-02 | P1 | Spend/approval rules are evaluated from an effective-dated snapshot | Threshold and policy-version tests |
| KYC-01 | P0 | Providers cannot publish/accept until required KYC/KYB and payout checks pass | State-machine and bypass tests |
| KYC-02 | P0 | Automated failures that affect access enter review; user can appeal | Case trail and appeal E2E |
| CAT-01 | P0 | Admin manages versioned category tree; providers manage approved listings | Slug/tree constraint and permission tests |
| CAT-02 | P0 | Search supports text, category, price, rating, availability and distance | Search contract/performance tests |
| JOB-01 | P0 | Customer creates an editable structured request with media | Validation, virus scan and ownership tests |
| AI-01 | P1 | AI converts text/media into a typed draft with assumptions/confidence | Schema/eval gate and manual fallback |
| AI-02 | P1 | Pricing returns range, duration, confidence and evidence version | Calibration report by category |
| AI-03 | P1 | Matchmaking hard-filters eligibility then ranks with reason codes | Offline/online and fairness metrics |
| BKG-01 | P0 | Scheduled and instant booking reserve capacity without double-booking | Concurrent booking test |
| BKG-02 | P1 | Emergency booking uses explicit surcharge, radius and response SLA | Policy snapshot and timeout test |
| JOB-02 | P0 | Only allowed actors can perform valid state transitions | Transition matrix negative tests |
| JOB-03 | P0 | Transition timeline is immutable and records actor, time, evidence, reason | Audit query and trigger test |
| PAY-01 | P0 | Provider webhook is signature-verified, deduplicated and reconciled | Replay/tamper/amount mismatch tests |
| PAY-02 | P0 | Every monetary event posts a balanced, append-only ledger transaction | Deferred balance constraint/test |
| PAY-03 | P0 | Release/refund/payout follows state, dispute, risk and approval rules | Scenario/dual-control tests |
| PAY-04 | P0 | Daily reconciliation reports zero unexplained variance | Staging certification evidence |
| COM-01 | P0 | Job participants exchange durable messages and permitted private files | RLS, ordering and retry tests |
| COM-02 | P1 | Typing/read receipts and translation degrade without losing messages | Realtime fallback test |
| LOC-01 | P1 | Exact live location is visible only during an active job to participants | Consent, authorization and expiry tests |
| REV-01 | P0 | One verified review per eligible completed job; moderation and appeal | Constraint and workflow tests |
| DSP-01 | P0 | A dispute locks disputed release and maintains evidence/decision timeline | Financial race-condition tests |
| INV-01 | P0 | Immutable numbered invoice/receipt contains tax and fee snapshots | Sequence, totals and PDF snapshot tests |
| NTF-01 | P0 | In-app/email delivery is preference-aware, idempotent and retried | Provider contract and DLQ tests |
| ADM-01 | P0 | Staff queues expose only role-required data; privileged actions are audited | Matrix and masking tests |
| ANA-01 | P1 | Funnel, fulfilment, risk and finance metrics use versioned event definitions | Metric reconciliation |

## Non-functional requirements

| ID | Area | Target / rule | Verification |
|---|---|---|---|
| NFR-P01 | Web | Mobile p75 LCP ≤2.5 s, INP ≤200 ms, CLS ≤0.1 on key public routes | RUM by device/network |
| NFR-P02 | API | Ordinary API p95 ≤400 ms and p99 ≤1 s; AI/vendor routes have separate SLOs | Load test + production traces |
| NFR-P03 | Scale | Launch test: 1,000 concurrent sessions, 50 commands/s, 20 tracking updates/s; revisit quarterly | k6 scenarios and DB analysis |
| NFR-A01 | Availability | 99.9% monthly for booking/payment confirmation APIs | Synthetic and SLI dashboard |
| NFR-R01 | Recovery | RPO ≤15 min, RTO ≤2 h for tier-1 transactional data | Quarterly restore exercise |
| NFR-S01 | Security | No unresolved critical/high finding at launch; OWASP ASVS L2 baseline | SAST/DAST/pentest/threat model |
| NFR-S02 | Isolation | All exposed tables have RLS; service keys never reach clients | CI schema lint and negative tests |
| NFR-S03 | Audit | Privileged/financial events are tamper-evident and retained per policy | Control sample and access review |
| NFR-A11 | Accessibility | WCAG 2.2 AA for critical flows; keyboard/screen-reader usable | Automated + manual audit |
| NFR-I01 | Internationalization | Bahasa Indonesia first; locale/currency/time zone explicit; UTC persistence | Locale/time-boundary tests |
| NFR-O01 | Observability | Every request/job/webhook has correlation ID; secrets/PII are redacted | Log sampling and alert drill |
| NFR-D01 | Data | Retention/deletion/legal-hold jobs are measurable and auditable | Quarterly privacy control test |
| NFR-AI1 | AI | Versioned prompt/model/schema/eval; no silent production model change | Registry and release gate |
| NFR-C01 | Cost | Vendor usage and unit economics tagged by feature/tenant where lawful | Monthly FinOps report |

## Definition of done

A requirement is done only when acceptance tests pass, telemetry and runbook exist, permissions/RLS are reviewed, error/empty/loading/accessibility states work, migration has rollback/forward-fix guidance, documentation is updated and the product owner accepts it in staging.
