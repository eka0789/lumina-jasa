import { getPublicEnv } from "@/lib/env"
import { logEvent } from "@/lib/observability/logger"

export const dynamic = "force-dynamic"

export function GET(request: Request) {
  const requestId = request.headers.get("x-request-id") ?? crypto.randomUUID()
  logEvent("info", "health.checked", { requestId, supabaseConfigured: Boolean(getPublicEnv()) })
  return Response.json(
    {
      status: "ok",
      service: "lumina-jasa-web",
      version: process.env.APP_VERSION ?? "local",
      environment: process.env.APP_ENV ?? process.env.NODE_ENV,
      dependencies: { supabaseConfigured: Boolean(getPublicEnv()) },
      timestamp: new Date().toISOString(),
    },
    { headers: { "Cache-Control": "no-store", "x-request-id": requestId } },
  )
}
