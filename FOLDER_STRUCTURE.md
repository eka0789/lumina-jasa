# Production Folder Structure

```text
lumina-jasa/
├─ src/
│  ├─ app/
│  │  ├─ (marketing)/  (auth)/  (customer)/  (business)/  (provider)/  (staff)/
│  │  └─ api/v1/
│  ├─ modules/
│  │  ├─ identity/ catalog/ discovery/ jobs/ conversations/
│  │  ├─ trust/ payments/ disputes/ billing/ notifications/ intelligence/
│  │  └─ <module>/{domain,application,infrastructure,ui}/
│  ├─ components/{ui,layout,feedback,data-display}/
│  ├─ lib/{auth,db,api,validation,observability,security}/
│  ├─ hooks/  styles/{tokens,globals.css}/
│  └─ types/database.generated.ts
├─ supabase/
│  ├─ migrations/
│  ├─ functions/{payment-webhook,kyc-webhook,notification-dispatch}/
│  ├─ seed.sql
│  └─ tests/database/
├─ workers/{outbox,ai,invoices,reconciliation}/
├─ tests/{unit,integration,contract,e2e,fixtures}/
├─ docs/{adr,runbooks,threat-models}/
└─ .github/workflows/
```

## Module contract

`domain` contains entities, value objects, state machines and pure rules. `application` contains use cases and ports. `infrastructure` implements database/vendor adapters. `ui` contains module-specific components. Cross-module calls use exported application contracts or durable events, never another module’s repository.

## App Router rules

- Prefer Server Components; add `"use client"` only for interaction, browser APIs, realtime, or client state.
- Keep `page.tsx` thin and use module query services.
- Put REST endpoints under `/api/v1`. Reserve Server Actions for UI-local mutations that need no public integration contract.
- Validate environment variables at boot. Expose `NEXT_PUBLIC_` values only intentionally.
- Use route-level `error.tsx`, `loading.tsx`, `not-found.tsx` and Suspense boundaries.
- Keep service-role and vendor-secret clients in `server-only` modules.
- SQL uses `snake_case`; TypeScript uses `camelCase`; components use `PascalCase`.
- Migrations are immutable after deployment. Generate database types in CI and fail on drift.
