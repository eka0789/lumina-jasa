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
})
