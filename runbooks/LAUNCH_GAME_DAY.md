# Launch and Restore Game Day

## Preconditions

- Use an isolated staging/restore project with synthetic data and separate vendor sandbox accounts.
- Record incident commander, database owner, security owner, finance reconciler, communications owner, start time, approved recovery point, and evidence location.
- Confirm the production change window separately. This runbook does not authorize destructive production actions.

## Scenario 1: unsafe write path

1. Open `/admin/peluncuran` with an AAL2 admin account.
2. Disable the affected flow with a specific incident/change reason.
3. Verify a synthetic command fails closed and unaffected reads remain available.
4. Confirm `launch.feature_flag_changed` exists in `audit_logs` with actor, before/after state, reason, and correlation ID.
5. Re-enable only after the owner records the recovery condition and validates a synthetic command.

## Scenario 2: isolated restore

1. Capture the last known-good time and start the RTO clock.
2. Restore the approved backup/PITR point into a new isolated Supabase project.
3. Apply the matching application version with outbound payment, payout, notification, AI, and tracking integrations disabled.
4. Run all migrations and pgTAP tests, then execute:

   `psql "$RESTORE_DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/restore-verify.sql`

5. Compare entity counts with the source backup manifest. Investigate any unexplained variance.
6. Reconcile captured payments, refunds, holds, payouts, and PSP events after the recovery point.
7. Validate RLS with customer, provider, business, support, finance, compliance, and admin roles.
8. Validate storage references and signed-download boundaries.
9. Record achieved RPO/RTO. Do not promote the restored project when a critical check fails.

## Scenario 3: release probes

Run against the deployed staging artifact:

```powershell
$env:TARGET_URL='https://staging.example.com'
npm run release:headers
npm run release:load
```

Also capture accessibility results for sign-in, catalog, job request, booking, payment, dispute, business approval, privacy, moderation, and launch controls at keyboard-only and 200% zoom.

## Exit evidence

- timestamps and achieved RPO/RTO;
- immutable application/database versions;
- pgTAP, restore verification, reconciliation, header, load, accessibility, and security scan outputs;
- all kill-switch transitions and approvals;
- unresolved issues with owner, severity, deadline, and explicit launch decision.
