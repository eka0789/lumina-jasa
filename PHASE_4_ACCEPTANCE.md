# Phase 4 Trust/Business Acceptance

Phase 4 adds the pilot controls for disputes, refunds, verified reviews, business approvals, staff segregation, and privacy requests. This document separates repository evidence from operational sign-off that still requires a configured Supabase environment and real pilot roles.

## Repository evidence

| Control | Implementation | Automated evidence |
|---|---|---|
| Dispute and evidence | Participant-only audited commands open an eligible dispute, freeze the payment hold, and add evidence notes while active | `supabase/tests/0004_trust_business_privacy.test.sql` |
| Refund dual control | AAL2 support recommends a reasoned refund; a different AAL2 finance/admin actor approves it; production sandbox execution fails closed | pgTAP role-negative tests and balanced refund-ledger assertion |
| Verified review | Only the booking customer can publish one review after confirmed completion | pgTAP eligibility and duplicate rejection |
| Business workspace | Owner-managed memberships, threshold rule, snapshotted request, independent approver, and booking guard | pgTAP pre-approval rejection, self-approval rejection, and approved booking |
| Privacy workflow | Users submit auditable access/export/correction/deletion/consent requests; AAL2 compliance/admin records a reasoned outcome | pgTAP submission and completion assertions |
| Staff segregation | Direct trust-table writes are revoked; privileged mutations are security-definer commands with explicit role, AAL2, reason, and audit checks | Migration grants plus negative role tests |

Customer trust actions are available at `/pesanan/[id]/kepercayaan`, business controls at `/bisnis`, privacy self-service at `/akun/privasi`, and staff queues at `/admin/kepercayaan`.

## Exit gate

Repository acceptance requires `npm run check` and the full Supabase migration/pgTAP workflow to pass. Before production or a financial UAT sign-off, also record:

- customer, provider, support, finance, compliance, requester, and independent approver UAT evidence;
- PSP refund certification outside the deliberately sandbox-only command;
- legal approval for dispute, refund, privacy, retention, and business-authority wording;
- accessibility review of the new role surfaces;
- audit-log sampling that proves actor, reason, correlation ID, and resource linkage;
- staging reconciliation showing the refund transaction balances and matches the PSP event.

Phase 4 is code-complete only when repository gates pass. Its roadmap exit criterion remains pending until the operational financial, security, and UAT evidence above is signed off.
