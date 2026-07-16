# Frontend State Management

Use the narrowest owner for each state. Avoid a global store until a demonstrated cross-tree client-state need exists.

| State | Owner | Examples |
|---|---|---|
| Durable business state | PostgreSQL via server query/command | bookings, jobs, messages, payments |
| Initial route data | Server Components | catalog page, booking summary, dashboard shell |
| Interactive server cache | TanStack Query | paginated messages, matches, notifications |
| Form/draft | React Hook Form + Zod | job wizard, provider listing, dispute evidence |
| URL state | typed search params | filters, sort, tab, cursor/shareable view |
| Ephemeral local | component `useState`/reducer | drawer, selection, optimistic input |
| Realtime signal | Supabase channel feeding query cache | new message, job update, notification |
| Auth | Supabase server/client session | identity and session refresh |

## Query rules

- Central key factories: `booking.detail(id)`, `messages.list(conversationId, filters)`.
- Server Components prefetch and dehydrate only where client interactivity needs the cache.
- Set freshness by volatility: categories long, matches short, payment/tracking effectively live.
- Realtime events carry entity ID/version. Invalidate or merge only if incoming version is newer.
- Reconnect performs canonical refetch; do not assume every broadcast arrived.
- Optimistic updates are limited to reversible actions such as mark-read/favorite. Payment, booking transitions and disputes wait for server confirmation.

## Mutations and conflicts

- Client creates an idempotency UUID for retryable commands and reuses it until outcome is known.
- Versioned edits send `If-Match`; `409` shows a compare/refresh experience.
- Disable duplicate submit visually, but rely on server idempotency for correctness.
- Failed background upload preserves draft and offers retry/remove.
- Mutations invalidate the smallest query set and announce completion/errors accessibly.

## Multi-step jobs

The wizard is a reducer/state machine: `describe → details → schedule → location → estimate → matches → review`. Each step has a Zod schema; server draft is source of truth after sign-in. Media uploads use upload intents and may complete independently. AI patches only untouched fields and is shown as a suggestion, never overwriting user edits.

## Realtime channels

Subscribe only on active screens, use private topics, unsubscribe on cleanup and bound retained events. Typing/presence is ephemeral broadcast with expiry. Messages persist first. Tracking batches UI updates to avoid render storms and labels stale data after the configured threshold.

## Persistence and privacy

Do not store tokens, KYC, chat bodies, exact location or payment data in local storage. A minimal non-sensitive job draft may use encrypted/platform storage only after privacy review; otherwise keep it in memory/server. Clear tenant-specific caches on logout, role/tenant switch and session revocation.
