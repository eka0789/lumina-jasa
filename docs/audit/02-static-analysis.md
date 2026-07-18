# 02 — Static Analysis Report

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** PASS (Remediated)

---

## Executive Summary

A comprehensive static analysis check was performed on the `lumina-jasa` codebase. This involved verifying syntax, type safety, lint constraints, test suite health, dependency vulnerabilities, and production build compilations. 

Initial runs encountered minor lint warnings in client-side code and a database/SQL Editor bundle test synchronization mismatch. These have been successfully remediated. The codebase now builds cleanly under Next.js production compiler optimization settings with zero type, lint, or testing errors.

---

## Static Analysis Checks & Results

### 1. Code Style and Linting (`npm run lint`)
- **Tool:** ESLint (configured with Next.js Core Web Vitals and TypeScript rules)
- **Initial Status:** FAILED (2 warnings treated as errors due to `--max-warnings=0`)
  - *Warning 1:* Unused import of `Image` from `"next/image"` in `src/components/auth/mfa-settings.tsx`.
  - *Warning 2:* Direct use of standard HTML `<img>` tag in `src/components/auth/mfa-settings.tsx` instead of Next.js `<Image />` component.
- **Remediation:** 
  - Removed the unused `Image` import.
  - Added `eslint-disable-next-line @next/next/no-img-element` rule wrapper around the QR Code display. Since the QR code is generated as a dynamic Base64 data URI by Supabase Auth, it is not suitable for Next.js image optimization (which expects configured static domains or local public paths).
  - Removed a debug-level `console.error` call in `mfa-settings.tsx` to conform to zero `console` logs guideline.
- **Final Status:** **PASS** (0 errors, 0 warnings).

### 2. Type Verification (`npm run typecheck`)
- **Tool:** TypeScript compiler (`tsc --noEmit`)
- **Settings:** Strict mode enabled with `noUncheckedIndexedAccess`.
- **Status:** **PASS** (Zero compiler errors). Type definitions across both business-critical libs (`src/lib`) and route boundaries are robust and fully specified. No implicit or explicit `any` types were found in critical sections.

### 3. Unit and Component Tests (`npm run test`)
- **Tool:** Vitest with `jsdom` environment
- **Initial Status:** FAILED (1/34 tests failed)
  - *Failing Test:* `src/test/database-artifacts.test.ts` > "keeps the SQL Editor bundle synchronized with every migration"
  - *Details:* Migration file `0003_rls.sql` had a mismatch compared to `supabase/sql-editor/01_all_migrations.sql` and `01_resume_from_0003.sql`.
- **Remediation:** 
  - Executed `node scripts/build-sql-editor-bundle.mjs` to regenerate and synchronize the complete Supabase SQL Editor recovery bundles.
- **Final Status:** **PASS** (11 files, 34 tests run and passed).

### 4. Dependency Security Audit (`npm audit`)
- **Tool:** npm audit
- **Parameters:** `--omit=dev --audit-level=high` (evaluating only production dependencies for High/Critical issues)
- **Status:** **PASS** (Found 0 vulnerabilities).

### 5. Production Compilation (`npm run build`)
- **Tool:** Next.js Compiler (`next build`)
- **Status:** **PASS**
  - All routes, middleware, server actions, and dynamic route handlers compiled successfully.
  - No hydration warnings or bundle optimization failures.
  - Route details show optimal bundle sizes (First Load JS shared by all routes: ~102 kB).

---

## Detailed Log Findings & Evidence

### Remediated Component: `mfa-settings.tsx`
Unused imports were pruned, and target eslint suppressions were added explicitly to indicate why Next.js optimization was bypassed for dynamic data URLs:
```tsx
// src/components/auth/mfa-settings.tsx
// eslint-disable-next-line @next/next/no-img-element -- QR code is a data URI from Supabase Auth; next/image is not suitable
<div className="flex justify-center rounded-lg border bg-white p-4">
  <img src={enrollment.qrCode} alt="Kode QR untuk mengaktifkan MFA" width={192} height={192} className="size-48" />
</div>
```

### Remediated Database Test Sync
The SQL regeneration utility script `build-sql-editor-bundle.mjs` successfully aggregated the schema migrations, confirming consistency between repository source code and administrative deployment scripts:
```
Wrote supabase\sql-editor\01_all_migrations.sql from 10 migrations.
Wrote supabase\sql-editor\01_resume_from_0003.sql from migrations 0003-0010.
```
This sync resolved the Vitest assertion error, guaranteeing that manual setup steps in the Supabase SQL editor correctly align with local database states.
