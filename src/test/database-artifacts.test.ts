import { readdirSync, readFileSync } from "node:fs"
import path from "node:path"
import { describe, expect, it } from "vitest"

const root = process.cwd()
const assertionNames = ["ok", "is", "isnt", "lives_ok", "throws_ok", "has_table", "has_column", "col_type_is", "results_eq", "set_eq", "bag_eq", "row_eq", "cmp_ok", "is_empty", "isnt_empty", "matches", "doesnt_match", "like", "unlike", "pass", "fail"]

describe("database test artifacts", () => {
  it("keeps every pgTAP plan equal to its assertion count", () => {
    const files = readdirSync(path.join(root, "supabase", "tests")).filter((file) => file.endsWith(".sql"))
    expect(files).toHaveLength(7)
    for (const file of files) {
      const sql = readFileSync(path.join(root, "supabase", "tests", file), "utf8")
      const planned = Number(sql.match(/select\s+plan\((\d+)\)/i)?.[1])
      const assertions = assertionNames.reduce((count, name) => count + [...sql.matchAll(new RegExp(`select\\s+${name}\\s*\\(`, "gi"))].length, 0)
      expect(assertions, file).toBe(planned)
    }
  })

  it("keeps migrations sequential and transaction-wrapped", () => {
    const files = readdirSync(path.join(root, "supabase", "migrations")).filter((file) => file.endsWith(".sql")).sort()
    expect(files).toHaveLength(10)
    files.forEach((file, index) => {
      expect(file.startsWith(String(index + 1).padStart(4, "0")), file).toBe(true)
      const sql = readFileSync(path.join(root, "supabase", "migrations", file), "utf8").trim()
      expect(sql.toLocaleLowerCase("en-US").startsWith("begin;"), file).toBe(true)
      expect(sql.toLocaleLowerCase("en-US").endsWith("commit;"), file).toBe(true)
    })
  })

  it("keeps the SQL Editor bundle synchronized with every migration", () => {
    const files = readdirSync(path.join(root, "supabase", "migrations")).filter((file) => file.endsWith(".sql")).sort()
    const bundle = readFileSync(path.join(root, "supabase", "sql-editor", "01_all_migrations.sql"), "utf8")
    let cursor = 0
    for (const file of files) {
      const header = `-- ${file}`
      const sql = readFileSync(path.join(root, "supabase", "migrations", file), "utf8").trim()
      const headerAt = bundle.indexOf(header, cursor)
      const sqlAt = bundle.indexOf(sql, headerAt)
      expect(headerAt, file).toBeGreaterThanOrEqual(cursor)
      expect(sqlAt, file).toBeGreaterThan(headerAt)
      cursor = sqlAt + sql.length
    }

    const resume = readFileSync(path.join(root, "supabase", "sql-editor", "01_resume_from_0003.sql"), "utf8")
    expect(resume).not.toContain("-- 0001_initial_schema.sql")
    expect(resume).not.toContain("-- 0002_finance_trust_operations.sql")
    expect(resume).toContain("-- 0003_rls.sql")
    expect(resume).toContain("-- 0010_scale_foundation.sql")
  })

  it("ships connected demo identities and a verification query", () => {
    const seed = readFileSync(path.join(root, "supabase", "sql-editor", "02_demo_seed.sql"), "utf8")
    const verify = readFileSync(path.join(root, "supabase", "sql-editor", "03_verify.sql"), "utf8")
    expect(seed.match(/@demo\.luminajasa\.id/g)).toHaveLength(18)
    for (const functionName of ["submit_job_request", "submit_job_quote", "accept_quote_and_create_booking", "send_moderated_message", "create_business", "submit_emergency_job_request", "open_fraud_case", "refresh_demand_forecast"]) {
      expect(seed, functionName).toContain(`public.${functionName}`)
    }
    expect(seed).toContain("grant select,insert,update on table demo_ids to authenticated")
    const transactionMigration = readFileSync(path.join(root, "supabase", "migrations", "0006_transaction_pilot.sql"), "utf8")
    expect(transactionMigration).not.toMatch(/\bdigest\s*\(/i)
    expect(transactionMigration.match(/pg_catalog\.sha256/g)).toHaveLength(3)
    const rlsMigration = readFileSync(path.join(root, "supabase", "migrations", "0003_rls.sql"), "utf8")
    expect(rlsMigration).toContain("private.is_conversation_participant(conversation_id)")
    expect(rlsMigration).not.toMatch(/from public\.conversation_participants p where p\.conversation_id = conversation_participants\.conversation_id/i)
    expect(verify).toContain("demo_users")
    expect(verify).toContain("having sum(e.amount)<>0")
  })
})
