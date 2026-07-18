# Bug Register

This register tracks all identified security, operational, and logic defects across the Lumina Jasa codebase.

---

## 1. Registry of Critical and High Severity Issues

### F-01: Provider Role Mismatch (High Severity)
- **Component:** Telemetry (`publish_tracking_point` database RPC)
- **Description:** 
  The check constraint on `provider_members.role` only permits `'owner'`, `'manager'`, and `'worker'`. However, the telemetry recording RPC function checked against `array['owner','dispatcher','technician']`. Because `'dispatcher'` and `'technician'` cannot exist in `provider_members.role`, provider technicians (`'worker'`) were blocked from sharing location updates during bookings.
- **Root Cause:** A mismatch between roles declared in the table check constraint and those queried in the RPC function's validation lookup.
- **Remediation:** 
  Updated the RPC function check inside `supabase/migrations/0008_ai_realtime_mvp.sql` to check `array['owner','manager','worker']` instead.
- **Verification:** 
  Added a pgTAP integration test in `supabase/tests/0005_ai_realtime_mvp.test.sql` inserting a member with a `'worker'` role and asserting that location coordinates can be published successfully. All tests passed.
- **Status:** `fixed and verified`

---

## 2. Registry of Medium Severity Issues

### F-05: Sandbox Payments in Production (Medium Severity)
- **Component:** Payments / RPC
- **Description:** 
  Platform payments and refunds are sandbox-only (`capture_sandbox_payment` and `approve_sandbox_refund`). They are hardcoded to check environment variables and raise an exception if `app.environment` is set to `'production'` or undefined (falling back to production).
- **Status:** `blocked`
- **Technical Reason:** The application is explicitly designed with a sandbox payments engine for the transaction pilot phase. Real payment gateway integrations (e.g. Midtrans or Xendit webhook handlers) are planned for the next scale phase and cannot be implemented without gateway API credentials and contract routing.

---

## 3. Registry of Low Severity Issues

### F-02: Lint Warnings in MFA Settings (Low Severity)
- **Component:** Frontend (`mfa-settings.tsx`)
- **Description:** Unused Next.js `Image` import and use of direct standard `<img>` tags for Base64 QR code rendering caused ESLint compilation tasks to fail.
- **Remediation:** Removed the unused import and added an explicit `eslint-disable-next-line @next/next/no-img-element` bypass.
- **Verification:** ESLint checker runs with zero warnings.
- **Status:** `fixed and verified`

### F-03: SQL Editor Bundle Out of Sync (Low Severity)
- **Component:** CI/CD / Scripts
- **Description:** Database recovery SQL files in `supabase/sql-editor/` were missing updates from migration `0003_rls.sql`, causing Vitest test suites checking script synchronization to fail.
- **Remediation:** Ran the build script `build-sql-editor-bundle.mjs` to regenerate the synced SQL Editor outputs.
- **Verification:** Vitest test suite passes successfully.
- **Status:** `fixed and verified`

### F-04: Client Route Auth Protection (Low Severity)
- **Component:** Next.js Routing
- **Description:** Protected paths (like `/pesanan`, `/pesan`, `/mitra`) rely on client-side state checks and server-side RPC validation instead of centralized Next.js middleware routing.
- **Status:** `blocked`
- **Technical Reason:** This is a design decision. Component-level checking coupled with database RLS policies provides secure, fail-closed boundaries. Centralizing this check into Next.js middleware is optional and would require restructuring session-state management.
