# Phase 6 Launch Hardening Acceptance

Phase 6 adds repository-enforced launch controls and repeatable evidence collection. It does not claim that external certification, pentesting, recovery exercises, or executive/legal approvals have occurred.

## Automated repository evidence

| Gate | Evidence |
|---|---|
| Application quality | `npm run check`: lint, strict TypeScript, unit/component tests, production build |
| Browser security | Nonce CSP, HSTS, anti-framing, MIME, referrer, permissions, COOP/CORP and header unit/probe tests |
| Availability | Separate liveness and fail-closed readiness response at `/api/health?probe=readiness` |
| Accessibility baseline | Skip link, focus visibility, reduced motion, semantic named navigation and icon-control tests |
| Operational safety | Database-enforced kill switches for booking intake, payment capture, payout release, AI intake and tracking publication |
| Segregation | Only AAL2 admin/super-admin can change launch controls; every transition includes a reason and audit event |
| Operational analytics | AAL2 aggregate signals for active bookings, disputes, refunds, moderation, outbox backlog and AI fallback |
| Database controls | `supabase/tests/0006_launch_controls.test.sql` validates fail-closed controls and role/AAL boundaries |
| Supply-chain baseline | Locked install plus production dependency audit in CI |
| Staging probes | Bounded load and security-header scripts plus manually triggered release-evidence workflow |
| Recovery | Isolated restore procedure and SQL verification for ledger balance, booking totals, launch controls and references |

## Go-live decision record

The following evidence must be attached and approved before production launch:

- full migration rebuild and every pgTAP suite green in CI;
- accessibility audit of critical customer/provider/business/staff flows, including keyboard, screen reader, zoom and mobile;
- SAST, DAST, dependency/config/secret scans and independent pentest with zero unresolved critical/high findings;
- steady, spike, soak and recovery load evidence against the agreed traffic profile and SLOs;
- isolated PITR/backup restore game day meeting RPO ≤15 minutes and RTO ≤2 hours;
- PSP/KYC/webhook/refund/payout sandbox certification and daily reconciliation evidence;
- privacy, retention, tracking consent, prohibited-services, terms, payment wording and dispute-policy approval;
- on-call, monitoring, escalation, status communication and incident runbook exercise;
- pilot UAT with customer, provider, business requester/approver, support, finance, compliance and admin roles;
- named product, engineering, security, finance, operations, legal/compliance and executive approval.

Any failed critical gate keeps the launch decision at `NO-GO`. Exceptions require a documented owner, expiry, compensating control and approval from the accountable security/legal/finance owner; critical authorization or financial-correctness failures cannot be waived.
