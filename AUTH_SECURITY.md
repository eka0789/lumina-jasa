# Authentication, Authorization, Security and Privacy

This is an engineering control baseline, not legal certification. Indonesian privacy, payments, tax, KYC/KYB and sector obligations require qualified counsel and provider review.

## 1. Authentication

- Supabase Auth: email confirmation/password, Google OAuth and phone OTP.
- Web sessions use secure, `HttpOnly`, `SameSite=Lax` cookies through Supabase SSR patterns. Never store access tokens in local storage.
- Rotate refresh tokens, detect reuse, expose device/session revocation and revoke all sessions on credential compromise.
- MFA is mandatory for staff/provider payout changes; recent `aal2` is required for super-admin, refund approval, payout destination and sensitive exports.
- OAuth uses exact redirect allowlists and PKCE. OTP responses do not reveal account existence and are rate limited by IP/device/destination.
- Passwords are managed by Supabase Auth; application tables never store a password/hash.

## 2. Authorization

Use RBAC for capabilities and ABAC for resource context.

```text
allow = authenticated
    AND capability(role, action)
    AND relationship(user, resource)
    AND resource.state permits action
    AND tenant membership is active
    AND assurance level is sufficient
    AND risk/policy constraints pass
```

Authorization is enforced in three layers:

1. UI hides unavailable actions for clarity, never security.
2. Application services check capability, relationship and state with actionable errors.
3. PostgreSQL grants/RLS are the final data boundary.

Authorization data belongs in server-controlled `raw_app_meta_data` or database membership tables, never user-editable metadata. JWT membership claims may be stale; sensitive commands query current membership. Service/secret keys bypass RLS and are restricted to isolated server modules and narrowly scoped workers.

### Segregation of duties

- Refund requester cannot approve the same refund above the configured threshold.
- Compliance can decide verification but cannot move money.
- Finance can operate payment cases but sees masked KYC data.
- Support can recommend resolution but high-value decisions require finance/admin approval.
- Super-admin is break-glass: hardware-backed MFA where possible, short elevation, reason, alert and post-review.

## 3. Data classification

| Class | Examples | Control |
|---|---|---|
| Public | approved category, listing, provider display profile | cacheable, content moderated |
| Internal | operational aggregates, non-sensitive configuration | staff scope, audit |
| Confidential | contact, addresses, chat, job details, invoices | RLS, encryption, masked staff views |
| Restricted | identity documents, liveness, exact tracking, bank identifiers, fraud evidence | separate private bucket, strongest roles, JIT access, short retention |

Collect only necessary data. Tokenize/payment-provider-host card entry keeps card data out of Lumina Jasa systems. Hash normalized identifiers used for duplicate/fraud matching with a rotated keyed HMAC; plain hashes of phone/email are reversible by guessing.

## 4. OWASP-focused controls

| Risk | Controls |
|---|---|
| Broken access control | deny-by-default grants/RLS, relationship tests, object-ID negative tests |
| Cryptographic failures | TLS, provider-managed encryption at rest, KMS/secret manager, no secrets in logs |
| Injection | parameterized Supabase queries/RPCs, Zod allowlists, no dynamic SQL from users |
| Insecure design | state machines, threat models, dual control, abuse cases |
| Misconfiguration | IaC/config review, CSP, headers, disabled debug, environment separation |
| Vulnerable components | lockfiles, Dependabot/Renovate, SCA and urgent patch SLA |
| Auth failures | MFA, session rotation/revocation, OTP throttling, credential-stuffing detection |
| Integrity failures | signed webhooks, immutable migrations/artifacts, protected CI provenance |
| Logging failures | structured audit/security logs, correlation IDs, alerts and tested response |
| SSRF | outbound allowlist, URL parser, no arbitrary fetch proxy, metadata IP blocks |

Additional controls: CSRF protection on cookie-authenticated mutations via same-site cookies plus origin checks; strict CSP with nonces; output encoding; file MIME/signature/size validation, malware scan and image transcoding; signed short-lived downloads; safe markdown rendering; request body limits.

## 5. API and infrastructure protection

- Vercel firewall/WAF and rate limiting at the edge; application quotas by principal/tenant/action.
- Secrets are per environment, rotated, least-privileged and never prefixed `NEXT_PUBLIC_`.
- Production access uses SSO/MFA, minimal roles and reviewed access expiry.
- Separate development, staging and production Supabase/Vercel/vendor accounts; never copy production restricted data to lower environments.
- Dependency calls have timeouts, circuit breakers and bounded retries with jitter. Mutations retry only with idempotency.
- Logs redact authorization, cookies, tokens, documents, message bodies, exact coordinates and financial identifiers.

## 6. Payments and ledger security

- PSP-hosted/tokenized checkout; Lumina Jasa does not process raw card details.
- Verify webhooks using raw request bytes and current/previous rotating secret. Deduplicate provider event ID.
- Reconcile provider status, amount, currency, merchant/subaccount and booking before posting.
- Ledger entries are append-only and balanced. Reversal, refund, fee and payout are separate transactions.
- Payout account change triggers MFA, cooldown, notification and risk review.
- Daily provider settlement reconciliation and alert on any unexplained variance.
- “Escrow” UI copy ships only after PSP and legal approval; otherwise use accurate terms such as “payment held pending completion.”

## 7. AI security and safety

- Treat user content, retrieved text and OCR as untrusted data, never instructions.
- Model has no raw service key and no direct payment/KYC decision tools.
- Structured outputs are schema-validated, size bounded and checked by deterministic rules.
- Redact/minimize PII before model calls; document provider retention/data residency choices.
- Moderate content, but keep human review and appeals for access-affecting outcomes.
- Prevent cross-tenant retrieval by filtering authorized candidates before similarity ranking.
- Pin model versions, run evals and canary releases; log prompt/model/schema versions and input hashes.

OpenAI API data controls vary by endpoint and account configuration; verify the chosen setup rather than assuming zero retention: [OpenAI data controls](https://platform.openai.com/docs/models/default-usage-policies-by-endpoint).

## 8. Privacy operations

- Maintain a data inventory, purpose/legal basis, processor list, retention schedule and data-flow map.
- Obtain explicit, versioned consent for tracking, biometrics/liveness where applicable, marketing and optional AI reuse.
- Support access/export, correction, deletion/de-identification, consent withdrawal and appeal workflows.
- Protect legal/financial retention from deletion while separating it from active product identity.
- Complete DPIA-style assessments for biometrics, tracking, automated risk scoring and large-scale monitoring.
- Maintain vendor DPAs, breach notification responsibilities and cross-border transfer review.

Do not label the product “GDPR compliant” or “PDP compliant” based on technical features alone. Readiness requires organizational processes, legal basis and evidence.

## 9. Audit and incident response

Audit authentication changes, role/membership changes, staff reads of restricted records, verification decisions, blacklist changes, booking transitions, ledger operations, refunds, payouts, disputes, settings, exports and deletions. Record actor, action, resource, reason, correlation ID, timestamp and tamper-evident before/after hashes; avoid raw sensitive payloads.

Incident severity:

- SEV-1: funds integrity, restricted-data exposure, active account takeover, platform-wide outage.
- SEV-2: major booking/payment degradation, tenant-isolation near miss, critical vendor outage.
- SEV-3/4: localized degradation or low-impact defect.

For SEV-1: page on-call, freeze risky operations, preserve evidence, rotate/revoke credentials where relevant, reconcile money, notify leadership/legal, communicate through approved templates and run a blameless review with tracked actions.

## 10. Release security gates

- Threat models for auth, files, KYC, chat, tracking, booking, payment, disputes, staff and AI.
- RLS policy inventory and positive/negative pgTAP tests for every exposed table.
- SAST, SCA, secret scan, IaC/config scan, DAST and independent penetration test.
- No unresolved critical/high; accepted medium risks have owner and expiry.
- Restore drill, webhook replay/tamper drill, ledger reconciliation and incident tabletop pass.

Supabase requires RLS on exposed objects and separate grants/policies; functions require explicit `EXECUTE` review: [Securing the Supabase Data API](https://supabase.com/docs/guides/api/securing-your-api).
