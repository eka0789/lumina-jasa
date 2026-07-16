# Supabase SQL Editor package

Use this package only for a fresh development or staging Supabase project. The demo seed creates test identities and must never be run in production.

## Execution order

1. Open the Supabase project and select **SQL Editor**.
2. Create a new query, paste the complete contents of `01_all_migrations.sql`, then select **Run**. This installs all 10 versioned migrations in order.
3. Create a second query, paste `02_demo_seed.sql`, then select **Run**. This creates eight login accounts and connected demo records.
4. Create a third query, paste `03_verify.sql`, then select **Run**. Every boolean result must be `true`; the ledger query must return zero rows.
5. Copy the project URL and publishable key into `.env.local`, then restart `npm run dev`.

## Recovery from the `spatial_ref_sys` ownership error

If an earlier bundle failed in `0003_rls.sql` with `must be owner of table spatial_ref_sys`, migrations 0001 and 0002 were already committed while 0003 was rolled back. Do not rerun the complete bundle. Run `01_resume_from_0003.sql`, then continue with `02_demo_seed.sql` and `03_verify.sql`.

The corrected RLS migration now changes permissions only on tables owned by the migration role, so PostGIS-owned tables such as `spatial_ref_sys` are left untouched.

If the demo seed later fails with `function digest(text, unknown) does not exist`, the already-installed transaction functions still have their older pgcrypto lookup. Run `01_patch_installed_hash_functions.sql` once and confirm all three `patched` results are `true`, then rerun `02_demo_seed.sql` from the beginning. Fresh installs generated after this fix use built-in, schema-qualified SHA-256 functions and do not need the patch.

If the seed fails with `infinite recursion detected in policy for relation "conversation_participants"`, run `01_patch_conversation_rls.sql` once. It replaces the recursive policy with a narrowly scoped `SECURITY DEFINER` membership helper, then recreates the conversation/message policies. Rerun `02_demo_seed.sql` from the beginning afterward.

Do not rerun `01_all_migrations.sql` after the schema exists. Apply only new versioned migrations after initial installation. The seed is intended for an empty demo dataset; rerunning it after users have exercised workflows can create additional business and operational records.

## Application environment

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
NEXT_PUBLIC_APP_URL=http://localhost:3000
APP_ENV=development
APP_VERSION=local
```

Use the publishable key, never the secret/service-role key, in a `NEXT_PUBLIC_` variable.

## Demo credentials

All accounts use `Demo12345!`.

| Role | Email |
| --- | --- |
| Customer | `customer@demo.luminajasa.id` |
| Provider | `provider@demo.luminajasa.id` |
| Support | `support@demo.luminajasa.id` |
| Finance | `finance@demo.luminajasa.id` |
| Compliance | `compliance@demo.luminajasa.id` |
| Admin | `admin@demo.luminajasa.id` |
| Business requester | `requester@demo.luminajasa.id` |
| Business approver | `approver@demo.luminajasa.id` |

Sensitive staff decisions enforce AAL2. Log in with the applicable staff account and enroll MFA at `/keamanan/mfa` before exercising those actions.

The verification queue contains metadata for a fake PDF. It intentionally does not create a real Storage object; upload a document through provider onboarding if a downloadable signed file is needed.

## Regenerating the migration bundle

After adding a migration, regenerate the SQL Editor bundle from the repository root:

```powershell
node scripts/build-sql-editor-bundle.mjs
```

Never edit `01_all_migrations.sql` manually; the versioned files under `supabase/migrations` remain the schema source of truth.
