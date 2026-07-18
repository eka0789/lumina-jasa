# Operations Manual & Runbooks

**Last Updated:** 2026-07-18  
**Owner:** Operations SRE Team  
**System:** Lumina Jasa Platform

---

## 1. Feature Flag Kill Switches (Incident Response)

Feature flags are the primary line of defense in the event of an outage or threat (e.g. payout leaks, spam campaigns, or downstream API failures).

### Target Flags
1. `booking_intake`: Stops new job creations.
2. `payment_capture`: Freezes transaction settlements.
3. `payout_release`: Disables payout disbursement processing.
4. `ai_intake`: Deactivates automated matchmaking recommendations.
5. `tracking_publish`: Disables provider location telemetry.

### Runbook: Activating a Kill Switch
1. Access the platforms administrative panel at `/admin/peluncuran`.
2. Locate the target flag card.
3. Enter the operational reason in the text area (minimum 10 characters).
4. Click **Hentikan** (Deactivate) or **Aktifkan** (Activate).
5. Verify the flag state updates in the dashboard.
6. The action is recorded in the platform's immutable `audit_logs` table for tracking.

---

## 2. Demand Forecast Refreshes (Weekly Operations)

Forecasting baselines project future consumer demand and inform provider scheduling.

### Runbook: Refreshing Service Projections
1. Access the administrative operations portal at `/admin/skala`.
2. Locate the **Forecast Permintaan** (Demand Forecast) card.
3. Select the target service from the dropdown (e.g., *Servis AC*, *Perbaikan Pipa*).
4. Click **Refresh baseline**.
5. The system queries the past 28 days of transaction volumes, generates projections, updates the `demand_forecasts` table, and logs the execution history.

---

## 3. Fraud Signals & Manual Reviews (Compliance Operations)

When automated fraud filters flag account anomalies, the compliance team must review the cases manually.

### Runbook: Manual Account Evaluation
1. Access the administrative dashboard at `/admin/skala`.
2. In the **Sinyal fraud manual** section, enter the target account identifier:
   - `User ID` (required)
   - `Booking ID` (optional, for transaction-specific fraud)
   - `Score` (numerical risk rating, scale `0.0` to `1.0`)
   - `Reason` (description of anomalies or verified alerts, minimum 10 characters)
3. Click **Catat sinyal** to save the signal record, or click **Buka kasus** to open a formal fraud case.
4. Active cases appear in the **Kasus fraud aktif** queue. Review the evidence and select the resolution:
   - **Bersihkan (Clear):** Dismisses the alert and restores normal account functions.
   - **Konfirmasi (Confirm):** Confirms the account is fraudulent. This records the action in `audit_logs` and supports account suspension.
5. **Security Policy:** Case resolutions require the `'compliance'` role and an active AAL2 (MFA-verified) session. Operators cannot resolve cases they opened themselves.
