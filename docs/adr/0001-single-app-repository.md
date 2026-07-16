# ADR 0001: Single-app repository for the foundation

- Status: accepted for Phase 1 implementation; owner review required before production promotion
- Date: 2026-07-16

## Context

The roadmap used “monorepo” as a Phase 1 outcome, but the current foundation has one deployable Next.js application and one colocated Supabase schema. Creating empty workspace packages would add tooling and dependency boundaries without a second independently versioned consumer.

## Decision

Keep one repository with clear application, database, test and documentation boundaries. Adopt npm workspaces only when a second deployable or genuinely shared package exists, such as a worker, component package or generated contract package.

CI treats the web application and database as separate jobs. Database migrations remain independently executable and are not coupled to the Next.js build.

## Consequences

- Phase 1 has a deliberate repository boundary rather than a cosmetic monorepo scaffold.
- A second deployable triggers an ADR review and workspace migration.
- This exception must be approved by the technical owner when the Phase 1 acceptance record is signed.
