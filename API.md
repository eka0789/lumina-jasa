# REST API Specification

Base URL: `/api/v1`. Route Handlers expose stable integration contracts; browser-only convenience mutations may use Server Actions but call the same application services.

## 1. Conventions

- JSON UTF-8; timestamps RFC 3339 UTC; money `{ "amount": 150000, "currency": "IDR" }`.
- Auth: Supabase access token in secure server-managed cookies for web or `Authorization: Bearer` for approved clients.
- `Idempotency-Key` is required for booking, payment, refund, payout and state-transition commands.
- `If-Match: "<version>"` is required for versioned updates. Conflict returns `409`.
- Cursor pagination: `?limit=20&after=<opaque>`; maximum 100. Responses include `nextCursor`.
- Filtering is allowlisted. Never accept arbitrary SQL-like sort/filter strings.
- Personal/financial/admin responses use `Cache-Control: private, no-store`.
- Each response includes `X-Request-Id`; clients may send `X-Correlation-Id`.

### Success envelope

```json
{
  "data": { "id": "uuid", "status": "confirmed", "version": 3 },
  "meta": { "requestId": "01J..." }
}
```

### Error envelope

```json
{
  "error": {
    "code": "BOOKING_INVALID_TRANSITION",
    "message": "The booking cannot move from confirmed to closed.",
    "requestId": "01J...",
    "details": [{ "path": "status", "reason": "invalid_transition" }],
    "retryable": false
  }
}
```

Use `400` malformed, `401` unauthenticated, `403` unauthorized, `404` absent/hidden, `409` state/idempotency conflict, `422` semantic validation, `429` limited, `502/503` dependency failure. Do not expose stack traces or vendor secrets.

## 2. Endpoint catalog

### Identity and organizations

Authentication initiation/callback is handled by Supabase Auth; these endpoints manage application state.

| Method | Path | Purpose |
|---|---|---|
| GET/PATCH | `/me` | Read/update safe profile fields |
| GET/DELETE | `/me/sessions/{sessionId}` | List/revoke device session |
| POST | `/me/consents` | Record versioned consent |
| POST | `/me/export` | Queue data export |
| DELETE | `/me` | Queue deletion/de-identification workflow |
| POST | `/businesses` | Create business |
| GET/PATCH | `/businesses/{id}` | Business details/update |
| GET/POST | `/businesses/{id}/members` | List/invite member |
| PATCH/DELETE | `/businesses/{id}/members/{userId}` | Change role/remove member |
| GET/POST | `/businesses/{id}/approval-rules` | Read/create effective rule |

### Catalog and providers

| Method | Path | Purpose |
|---|---|---|
| GET | `/categories` | Active category tree |
| GET | `/services` | Filtered service definitions |
| GET | `/providers` | Search by category, availability, price, rating, distance |
| GET | `/providers/{idOrSlug}` | Public safe provider profile |
| POST | `/providers` | Start provider profile |
| PATCH | `/providers/{id}` | Update owned provider |
| GET/POST | `/providers/{id}/services` | List/create listing |
| PATCH | `/providers/{id}/services/{listingId}` | Update listing with version |
| GET/PUT | `/providers/{id}/availability` | Read/replace availability |
| POST/DELETE | `/providers/{id}/portfolio` | Add/remove portfolio item |
| POST | `/providers/{id}/verification` | Submit KYC/KYB package |
| GET | `/providers/{id}/earnings` | Provider-scoped earnings summary |

### Files

| Method | Path | Purpose |
|---|---|---|
| POST | `/files/upload-intents` | Validate metadata and return short-lived signed upload target |
| POST | `/files/{id}/complete` | Verify object, size/hash and queue malware scan |
| GET | `/files/{id}/download` | Authorized short-lived signed URL |
| DELETE | `/files/{id}` | Soft-delete if policy allows |

Never accept a client-provided bucket/path as authorization. Server derives both from purpose and principal.

### AI and discovery

| Method | Path | Purpose |
|---|---|---|
| POST | `/ai/intake` | Natural-language/media request to editable typed draft |
| POST | `/ai/pricing-estimates` | Price/duration interval and evidence |
| POST | `/ai/recommendations` | Eligible ranked provider results |
| POST | `/ai/search` | Hybrid lexical/semantic search |
| POST | `/ai/translate` | Translate permitted chat draft/message |
| POST | `/ai/feedback` | Accept/correct/reject prediction |
| GET | `/ai/runs/{id}` | Authorized async run status |

OCR/liveness are not exposed as arbitrary proxy endpoints. `/providers/{id}/verification` creates a vendor session, and signed `/webhooks/kyc/{provider}` receives results.

### Jobs, bookings and tracking

| Method | Path | Purpose |
|---|---|---|
| GET/POST | `/jobs` | List/create own job draft |
| GET/PATCH | `/jobs/{id}` | Read/edit eligible draft/request |
| POST | `/jobs/{id}/submit` | Freeze intake and start matching |
| GET | `/jobs/{id}/matches` | Ranked candidates and reason codes |
| POST | `/jobs/{id}/matches/{matchId}/select` | Select provider/quote |
| POST | `/bookings` | Create booking and payment intent |
| GET | `/bookings/{id}` | Participant view/timeline |
| POST | `/bookings/{id}/accept` | Provider accepts |
| POST | `/bookings/{id}/transition` | Perform allowlisted workflow action |
| POST | `/bookings/{id}/cancel` | Policy-evaluated cancellation |
| POST | `/bookings/{id}/confirm-completion` | Customer confirmation |
| POST | `/bookings/{id}/tracking-points` | Assigned provider location batch |
| GET | `/bookings/{id}/tracking` | Latest point/ETA for participant |

Transition request:

```json
{
  "action": "start_work",
  "occurredAt": "2026-07-16T03:15:00Z",
  "evidenceFileIds": ["uuid"],
  "reasonCode": null
}
```

The client sends an action, not an arbitrary target status. Server maps allowed actor/current state/action to the next state.

### Payment, escrow workflow, invoices and disputes

| Method | Path | Purpose |
|---|---|---|
| GET | `/bookings/{id}/payment` | Safe checkout/payment state |
| POST | `/bookings/{id}/payment-intents` | Start/retry provider checkout |
| GET | `/bookings/{id}/invoice` | Invoice metadata/signed PDF URL |
| POST | `/bookings/{id}/disputes` | Open eligible dispute and freeze amount |
| GET | `/disputes/{id}` | Case/timeline for participant |
| POST | `/disputes/{id}/evidence` | Submit note/file evidence |
| POST | `/disputes/{id}/appeal` | Create appeal within policy |
| POST | `/admin/disputes/{id}/resolve` | Reasoned resolution; may require second approval |
| POST | `/admin/refunds/{id}/approve` | Finance approval distinct from requester |
| POST | `/admin/payouts/{id}/retry` | Controlled payout retry |
| GET | `/admin/reconciliation` | Finance reconciliation exceptions |

### Chat, reviews and notifications

| Method | Path | Purpose |
|---|---|---|
| GET | `/conversations` | Participant conversations |
| GET/POST | `/conversations/{id}/messages` | Cursor history/send durable message |
| POST | `/conversations/{id}/read` | Advance read watermark |
| POST | `/messages/{id}/report` | Report message |
| POST | `/bookings/{id}/reviews` | Verified review |
| PATCH | `/reviews/{id}` | Edit in allowed window |
| POST | `/reviews/{id}/response` | Provider response |
| POST | `/reviews/{id}/report` | Moderation report |
| GET | `/notifications` | Notification inbox |
| POST | `/notifications/read` | Batch mark read |
| GET/PUT | `/notification-preferences` | Preference matrix |

Typing and presence use private Realtime broadcast; messages and read watermarks persist through the API/database.

### Admin, analytics and CMS

| Method | Path | Required scope |
|---|---|---|
| GET/PATCH | `/admin/users/{id}` | `users:read/manage` |
| GET/POST | `/admin/verifications` | `compliance:review` |
| GET/POST | `/admin/fraud-cases` | `risk:review` |
| GET/POST | `/admin/moderation` | `moderation:review` |
| CRUD | `/admin/categories` | `catalog:manage` |
| CRUD | `/admin/pricing-rules` | `pricing:manage` + approval |
| CRUD | `/admin/commission-rules` | `finance:policy` + approval |
| GET | `/admin/audit-logs` | `audit:read` |
| GET/POST | `/admin/settings` | `settings:manage`; versioned |
| GET | `/analytics/marketplace` | tenant/staff analytics scope |
| GET | `/analytics/provider` | provider scope |
| GET | `/analytics/business` | business scope |

Admin endpoints use explicit permissions, recent MFA for sensitive commands, `reason` in the request and an audit record. Search/list payloads mask sensitive data by default.

## 3. Example: create booking

```http
POST /api/v1/bookings
Authorization: Bearer <token>
Idempotency-Key: 87c2...
Content-Type: application/json

{
  "jobId": "uuid",
  "matchId": "uuid",
  "scheduledStart": "2026-07-20T02:00:00Z",
  "quoteVersion": 4,
  "paymentMethod": "EWALLET"
}
```

```json
{
  "data": {
    "id": "uuid",
    "status": "awaiting_payment",
    "version": 1,
    "payment": { "status": "pending", "checkoutUrl": "https://provider.example/...", "expiresAt": "2026-07-16T04:00:00Z" }
  },
  "meta": { "requestId": "01J..." }
}
```

The server revalidates quote, capacity, business approval, provider eligibility, policy version and total inside the transaction. Client totals are display-only.

## 4. Webhooks

Paths: `/webhooks/payments/{provider}`, `/webhooks/kyc/{provider}`, `/webhooks/notifications/{provider}`. These are Edge Functions or isolated server endpoints.

- Verify against the raw body using the provider’s documented scheme; rotate secrets.
- Enforce a timestamp/replay window when available.
- Deduplicate `(provider, event_id)` indefinitely for the required financial retention period.
- Return 2xx after durable receipt; retry processing asynchronously.
- Treat event order as non-deterministic. State moves monotonically or is reconciled by fetch.
- Log payload hashes and redacted metadata, not reusable secrets or raw identity documents.

## 5. Rate-limit classes

| Class | Examples | Initial policy |
|---|---|---|
| Auth/OTP | OTP request/verify | strict per IP, account, device and phone; progressive challenge |
| AI/media | intake, pricing, upload intent | per user/tenant quota, file/type/size limits, concurrency cap |
| Commands | booking, transition, dispute | per principal plus idempotency; abuse signal on bursts |
| Read/search | catalog/search | IP/user token bucket; cached public reads |
| Webhooks | vendor endpoints | signature first, provider/source limit, queue backpressure |

Exact numbers are load- and abuse-tested configuration, not hard-coded in handlers.

## 6. API lifecycle

Publish OpenAPI from Zod schemas, run consumer/provider contract tests and use additive changes within `/v1`. Deprecations publish a sunset date and telemetry. AI model changes do not change the endpoint schema without a versioned contract. Pin and evaluate model snapshots because model behavior can vary; see [OpenAI API compatibility guidance](https://platform.openai.com/docs/api-reference/backward-compatibility).
