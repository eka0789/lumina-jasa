import { describe, expect, it } from "vitest"
import { buildHealthReport } from "@/lib/health"

describe("health probes", () => {
  it("keeps liveness healthy when a dependency is not configured", () => {
    expect(buildHealthReport({ probe: "liveness", supabaseConfigured: false, version: "test" }).status).toBe("ok")
  })

  it("fails readiness closed when Supabase is not configured", () => {
    const report = buildHealthReport({ probe: "readiness", supabaseConfigured: false, version: "test" })
    expect(report.status).toBe("degraded")
    expect(report.dependencies.supabaseConfigured).toBe(false)
  })
})
