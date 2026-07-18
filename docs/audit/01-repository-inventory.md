# 01 — Repository Inventory

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Repository:** `lumina-jasa` (Next.js App Router monorepo)

---

## Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Next.js (App Router) | 15.5.20 |
| Runtime | React | 19.1.0 |
| Language | TypeScript (strict) | 5.9.3 |
| Styling | Tailwind CSS | 3.4 |
| Animation | Framer Motion | 12.9 |
| Icons | Lucide React | 0.523 |
| Forms | React Hook Form + Zod | 7.56 / 3.25 |
| Backend | Supabase (PostgreSQL) | @supabase/supabase-js 2.50 |
| Auth | Supabase Auth + SSR | @supabase/ssr 0.7.0 |
| Database | PostgreSQL + pgvector + postgis | via Supabase |
| Testing | Vitest + jsdom | 3.2.7 |
| CI | GitHub Actions | ci.yml, release-evidence.yml |
| Linting | ESLint (next/core-web-vitals) | FlatCompat |

---

## Project Structure

```
lumina-jasa/
├── .github/workflows/
│   ├── ci.yml                    # lint → typecheck → test → build → npm audit → supabase test
│   └── release-evidence.yml
├── docs/
│   ├── adr/
│   │   └── 0001-single-app-repository.md
│   └── runbooks/
│       └── phase-1-restore.md
├── runbooks/
│   └── LAUNCH_GAME_DAY.md
├── scripts/
│   ├── build-sql-editor-bundle.mjs
│   ├── check-security-headers.mjs
│   ├── load-smoke.mjs
│   └── restore-verify.sql
├── src/
│   ├── app/
│   │   ├── (auth)/masuk/          # Sign-in page
│   │   ├── admin/                 # Admin dashboard (AAL2 protected)
│   │   ├── api/health/            # Health check endpoint
│   │   ├── bisnis/                # Business workspace
│   │   ├── layanan/               # Service catalog (public)
│   │   ├── mfa/                   # MFA setup
│   │   ├── pesan/                 # Messaging
│   │   ├── permintaan/[id]/       # Job request detail
│   │   ├── pesanan/[id]/          # Booking detail
│   │   │   └── kepercayaan/       # Trust (dispute/review) page
│   │   ├── privasi/               # Privacy center
│   │   └── profil-mitra/[slug]/   # Provider profile (public)
│   ├── components/
│   │   ├── admin/                 # 5 admin components
│   │   ├── auth/                  # sign-in-form, mfa-settings
│   │   ├── business/              # business-workspace
│   │   ├── privacy/               # privacy-center
│   │   ├── provider/              # onboarding-form
│   │   ├── transaction/           # 8 transaction components
│   │   ├── trust/                 # customer-trust-actions
│   │   └── ui/                    # badge, button, card, input
│   ├── lib/
│   │   ├── ai/
│   │   │   ├── ranking.ts         # Deterministic provider ranking
│   │   │   └── forecast.ts        # Historical baseline forecast
│   │   ├── auth/
│   │   │   └── aal.ts             # AAL2 path enforcement
│   │   ├── observability/
│   │   │   └── logger.ts          # Structured logging + sanitization
│   │   ├── security/
│   │   │   └── headers.ts         # CSP + security headers
│   │   ├── supabase/
│   │   │   ├── client.ts          # Browser Supabase client
│   │   │   ├── server.ts          # Server-only Supabase client
│   │   │   └── middleware.ts      # Session refresh + CSP
│   │   ├── booking-workflow.ts    # State machine transitions
│   │   ├── catalog.ts             # Service catalog loader
│   │   ├── catalog-search.ts      # Search normalization
│   │   ├── env.ts                 # Zod-validated environment
│   │   ├── health.ts              # Health check builder
│   │   └── utils.ts               # Utilities (formatRupiah, cn)
│   └── test/                      # Test helpers and mocks
├── supabase/
│   ├── migrations/                # 10 sequential migrations
│   ├── sql-editor/                # SQL Editor bundles
│   └── tests/                     # 7 pgTAP test suites
├── .env.example
├── eslint.config.mjs
├── middleware.ts
├── next.config.ts
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

---

## Database Schema (10 Migrations)

| Migration | Description | Key Tables/Functions |
|---|---|---|
| 0001_initial_schema | Core tables, extensions, profiles | `profiles`, `categories`, `services`, `providers`, `jobs`, `bookings`, `messages`, `notifications` |
| 0002_finance_trust_operations | Ledger, payments, disputes, audit | `ledger_accounts`, `ledger_transactions`, `payment_intents`, `disputes`, `refunds`, `audit_logs` |
| 0003_rls | RLS policies, security helper functions | 45+ policies, `private.is_provider_member()`, `private.is_booking_participant()`, `private.has_platform_role()` |
| 0004_supply_catalog | Provider onboarding, verification, storage | `submit_provider_onboarding()`, `review_provider_verification()`, Storage bucket policies |
| 0005_catalog_seed | Seed data | 4 categories, 6 services |
| 0006_transaction_pilot | Quotes, booking workflow, payment capture | `submit_job_request()`, `accept_quote_and_create_booking()`, `capture_sandbox_payment()`, `transition_booking()` |
| 0007_trust_business_privacy | Business entities, disputes, reviews, privacy | `create_business()`, `open_booking_dispute()`, `submit_verified_review()`, `submit_privacy_request()` |
| 0008_ai_realtime_mvp | AI intake, chat, tracking, moderation | `suggest_job_intake()`, `send_moderated_message()`, `publish_tracking_point()`, Realtime publication |
| 0009_launch_controls | Feature flags, kill switches, metrics | `platform_feature_flags`, `set_platform_feature_flag()`, `get_launch_metrics()` |
| 0010_scale_foundation | Ranking models, forecasts, fraud | `ranking_model_versions`, `demand_forecasts`, `submit_emergency_job_request()`, `decide_fraud_case()` |

---

## Security Architecture

### Authentication
- Supabase Auth with email/password
- TOTP MFA with AAL2 enforcement
- Middleware-level session refresh via `@supabase/ssr`
- AAL2 required for `/admin`, `/operasional`, `/keuangan` routes

### Authorization (RLS)
- All tables have RLS enabled
- Helper functions in `private` schema: `is_provider_member()`, `is_business_member()`, `is_booking_participant()`, `is_conversation_participant()`, `has_platform_role()`
- All helper functions: `SECURITY DEFINER`, `SET search_path = ''`, `REVOKE ALL FROM PUBLIC`
- Critical business RPCs: `SECURITY DEFINER` with auth checks

### Environment
- Public env vars validated via Zod (`env.ts`)
- `server-only` import guard on server modules
- No `service_role` key in source code
- `.env.local` properly gitignored (not tracked)

### Headers
- CSP with nonce per request
- HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- Permissions-Policy restricting camera, microphone, geolocation

---

## Test Coverage

| Suite | Tests | Framework |
|---|---|---|
| `database-artifacts.test.ts` | 4 | Vitest |
| `booking-workflow.test.ts` | 3 | Vitest |
| `ranking.test.ts` | 2 | Vitest |
| `forecast.test.ts` | 3 | Vitest |
| `aal.test.ts` | 9 | Vitest |
| `logger.test.ts` | 2 | Vitest |
| `headers.test.ts` | 2 | Vitest |
| `health.test.ts` | 2 | Vitest |
| `catalog-search.test.ts` | 3 | Vitest |
| `utils.test.ts` | 2 | Vitest |
| `site-header.test.tsx` | 2 | Vitest |
| **Total (Application)** | **34** | |
| 7 pgTAP database test suites | 75+ assertions | pgTAP |

---

## CI Pipeline

```yaml
# ci.yml - 3 parallel jobs
application:    npm ci → npm run check (lint + typecheck + test + build)
dependency-audit: npm audit --omit=dev --audit-level=high
database:       supabase start → supabase db reset → supabase test db
```
