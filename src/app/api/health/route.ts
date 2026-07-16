import { getPublicEnv } from "@/lib/env"

export const dynamic = "force-dynamic"

export function GET() {
  return Response.json(
    {
      status: "ok",
      service: "lumina-jasa-web",
      version: process.env.APP_VERSION ?? "local",
      environment: process.env.APP_ENV ?? process.env.NODE_ENV,
      dependencies: { supabaseConfigured: Boolean(getPublicEnv()) },
      timestamp: new Date().toISOString(),
    },
    { headers: { "Cache-Control": "no-store" } },
  )
}
