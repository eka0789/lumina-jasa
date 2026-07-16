import { getPublicEnv } from "@/lib/env"
import { logEvent } from "@/lib/observability/logger"
import { buildHealthReport, type HealthProbe } from "@/lib/health"

export const dynamic = "force-dynamic"

export function GET(request: Request) {
  const requestId = request.headers.get("x-request-id") ?? crypto.randomUUID()
  const probe: HealthProbe = new URL(request.url).searchParams.get("probe") === "readiness" ? "readiness" : "liveness"
  const supabaseConfigured = Boolean(getPublicEnv())
  const report = buildHealthReport({ probe, supabaseConfigured, version: process.env.APP_VERSION ?? "local", environment: process.env.APP_ENV ?? process.env.NODE_ENV })
  logEvent(report.status === "ok" ? "info" : "warn", "health.checked", { requestId, probe, supabaseConfigured })
  return Response.json(
    {
      ...report,
      timestamp: new Date().toISOString(),
    },
    { status: report.status === "ok" ? 200 : 503, headers: { "Cache-Control": "no-store", "x-request-id": requestId } },
  )
}
