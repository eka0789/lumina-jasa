# Lumina Jasa — Enterprise Product & Engineering Blueprint

This repository contains the working **Next.js 15 foundation** and engineering blueprint for **Lumina Jasa**, an AI-assisted Indonesian service marketplace for B2C customers, business buyers, and verified service providers.

## Implemented foundation

- Responsive public landing, smart-search preview, provider onboarding and sign-in surfaces.
- Semantic three-layer design tokens, light/dark themes and accessible navigation/forms.
- Supabase browser/server clients, session-refresh middleware and OAuth callback.
- TOTP enrollment/challenge flow with AAL2 enforcement for sensitive route groups.
- Environment validation and `/api/health` readiness endpoint.
- Correlation IDs, redacting structured logs and an application instrumentation hook.
- Strict TypeScript, ESLint, Vitest and successful Next.js production build.
- Versioned PostgreSQL schema and baseline RLS migrations under `supabase/migrations`.
- GitHub Actions gates for clean builds, migration rebuilds and cross-tenant pgTAP tests.
- Transactional provider onboarding, AAL2-protected KYC/KYB review queue, verified public catalog and provider profiles.
- Manual request-to-quote flow, conflict-safe scheduled booking, fail-closed sandbox payment, balanced ledger, invoice, timeline and participant chat.
- Audited disputes/evidence, dual-control sandbox refunds, verified reviews, business approvals, and privacy request workflows.
- Editable smart-intake fallback, interpretable provider ranking, moderated realtime chat, opt-in arrival tracking, and human moderation queue.
- Nonce CSP/readiness hardening, audited launch kill switches, operational signals, bounded release probes, and restore verification.
- Initial scale foundation for bounded emergency dispatch, human-reviewed fraud signals, multichannel notification routing, forecast baselines, and ranking model registry.

## Run locally

```bash
npm install
copy .env.example .env.local
npm run dev
```

Open `http://localhost:3000`. Configure the Supabase URL and publishable key in `.env.local` to enable authentication. Never place a secret/service-role key in a `NEXT_PUBLIC_` variable.

Quality commands:

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

## Document map

| Document | Purpose |
|---|---|
| [PRD.md](PRD.md) / [REQUIREMENTS.md](REQUIREMENTS.md) | Product scope and traceable requirements |
| [ARCHITECTURE.md](ARCHITECTURE.md) / [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) | Runtime design and repository structure |
| [DATABASE.md](DATABASE.md) / [supabase/migrations/0001_initial_schema.sql](supabase/migrations/0001_initial_schema.sql) | Data model and executable schema/RLS migrations |
| [supabase/sql-editor/README.md](supabase/sql-editor/README.md) | Fresh-project SQL Editor bundle, connected demo seed and verification queries |
| [API.md](API.md) | REST conventions, endpoints, payloads and webhooks |
| [AUTH_SECURITY.md](AUTH_SECURITY.md) | Auth, RBAC/ABAC, security and privacy |
| [AI_SYSTEM.md](AI_SYSTEM.md) | AI modules, contracts, evaluation and governance |
| [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md) / [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md) | UX, tokens, components and frontend state |
| [TESTING.md](TESTING.md) / [ROADMAP.md](ROADMAP.md) | Quality strategy and phased delivery |
| [OPERATIONS.md](OPERATIONS.md) | CI/CD, deployment, observability, scaling and recovery |
| [PHASE_1_ACCEPTANCE.md](PHASE_1_ACCEPTANCE.md) | Phase 1 evidence map and remaining operational sign-off |
| [PHASE_2_ACCEPTANCE.md](PHASE_2_ACCEPTANCE.md) | Supply/catalog evidence map and pilot cohort exit gate |
| [PHASE_3_ACCEPTANCE.md](PHASE_3_ACCEPTANCE.md) | Transaction pilot controls and remaining staging evidence |
| [PHASE_4_ACCEPTANCE.md](PHASE_4_ACCEPTANCE.md) | Trust/business controls and remaining financial, security and UAT evidence |
| [PHASE_5_ACCEPTANCE.md](PHASE_5_ACCEPTANCE.md) | AI/realtime guardrails, degraded-mode evidence and remaining canary sign-off |
| [PHASE_6_ACCEPTANCE.md](PHASE_6_ACCEPTANCE.md) | Launch hardening evidence, go-live gates and external approval checklist |
| [PHASE_7_SCALE_FOUNDATION.md](PHASE_7_SCALE_FOUNDATION.md) | Ongoing scale tranche and quarterly outcome/economic gates |

## Binding architecture decisions

- Supabase Auth is the only identity system; do not add Auth.js.
- Versioned SQL migrations are the schema authority. Generated TypeScript types are read-only artifacts; do not run Prisma migrations in parallel.
- PostgreSQL grants plus RLS protect every exposed table. Privileged mutations use audited commands.
- Financial truth is an append-only double-entry ledger plus verified provider events. Job status is never a balance.
- AI is advisory. Deterministic rules constrain model output; humans decide high-impact KYC, fraud, dispute and compliance outcomes.
- Reliable side effects use a transactional outbox, idempotency keys, signed webhooks, retries and dead-letter handling.
- Business resources carry `business_id`; membership and role checks are enforced at the database and command layers.

## Delivery assumptions

- Initial market: Indonesia, IDR, `Asia/Jakarta`, Bahasa Indonesia first.
- Responsive web/PWA first; native apps are outside MVP.
- Xendit XenPlatform or an equivalent marketplace-capable licensed PSP is the preferred payment abstraction. “Escrow” describes the product workflow, not a claim that Lumina Jasa is a licensed escrow institution.
- KYC/KYB, tax, privacy, payout timing, fund holding and dispute rules require Indonesian legal/compliance approval before production.
- Performance and availability figures are engineering targets, not vendor guarantees.

Production launch requires P0 completion, RLS negative tests, migration/rollback rehearsal, PSP certification, threat-model closure, accessibility review, load evidence, backup restore evidence, incident runbooks, legal sign-off and a staged pilot.
