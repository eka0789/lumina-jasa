# Phase 1 Restore and Rebuild Runbook

## Clean local rebuild (every pull request)

Prerequisites: Docker and Supabase CLI.

```bash
supabase start
supabase db reset
supabase test db
```

Success means all migrations apply from an empty database and every pgTAP assertion passes. Stop and investigate any drift, missing extension, policy failure or seed dependency.

## Managed backup restore rehearsal

Perform this only in an approved isolated Supabase project. Never overwrite production as a test.

1. Record source project, backup/PITR timestamp, incident/change reference and approver.
2. Restore into the isolated project using the selected Supabase plan's documented restore workflow.
3. Apply only forward migrations that were committed after the restore point.
4. Run schema inventory, RLS tests, row-count/checksum samples and health checks with synthetic identities.
5. Confirm no email, webhook, payout, notification or worker side effects can reach real recipients.
6. Record achieved RPO/RTO, discrepancies and evidence links; destroy the isolated copy according to retention policy.

## Minimum verification queries

```sql
select version from supabase_migrations.schema_migrations order by version;

select n.nspname, c.relname, c.relrowsecurity
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by c.relname;
```

The restore fails acceptance if a public table lacks RLS, migration history differs from the release artifact, tenant-negative tests fail, or the measured RPO/RTO exceeds the target.
