# Phase 1 Acceptance Record

Status: **implemented; CI evidence required on the remote repository**.

This record maps the Phase 1 outcomes and exit criteria in `ROADMAP.md` to executable evidence. A local implementation is not a production approval: environment owners must still attach the first successful GitHub Actions run and an isolated managed-backup restore record before promoting a production environment.

| Criterion | Repository evidence | Automated gate |
|---|---|---|
| Repository and environments | `.env.example`, `supabase/config.toml`, environment validation in `src/lib/env.ts`; single-app exception in `docs/adr/0001-single-app-repository.md` | Next.js production build |
| CI | `.github/workflows/ci.yml` | application and database jobs |
| Supabase migrations and RLS | `supabase/migrations/0001..0003`, `supabase/tests/0001_rls_cross_tenant.test.sql` | clean `supabase db reset` and pgTAP |
| Authentication and MFA | Supabase SSR clients, middleware session refresh, `/keamanan/mfa`, AAL2 route policy | TypeScript, unit tests, production build |
| Observability baseline | request correlation IDs, structured redacting logger, instrumentation hook, health endpoint | logger tests and production build |
| Design tokens | semantic tokens and shared UI components | production build |
| Clean deploy | immutable install plus lint, typecheck, unit tests and production build | CI application job |
| Clean database rebuild | local stack rebuilt only from versioned migrations | CI database job |
| Cross-tenant isolation | positive/negative membership, object ownership and anonymous visibility tests | pgTAP database test |

## Required remote evidence

Before marking the operational exit gate approved, record:

- GitHub Actions run URL and commit SHA for both green jobs.
- Supabase CLI version emitted by the database job.
- Managed environment and backup restore timestamp, isolated target identifier, achieved RPO/RTO, verifier and result.
- Product/security owner approval and any accepted exceptions.
- Technical-owner approval of ADR 0001's single-app repository decision.

## Phase boundary

Phase 2 development may start after the repository gates pass. Production or pilot promotion remains blocked until the managed restore evidence above is attached; a local database rebuild does not prove vendor backup restoration.
