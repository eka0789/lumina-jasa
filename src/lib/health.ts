export type HealthProbe = "liveness" | "readiness"

export function buildHealthReport({ probe, supabaseConfigured, version, environment }: { probe: HealthProbe; supabaseConfigured: boolean; version: string; environment?: string }) {
  const ready = supabaseConfigured
  return {
    status: probe === "liveness" || ready ? "ok" as const : "degraded" as const,
    probe,
    service: "lumina-jasa-web",
    version,
    environment: environment ?? "unknown",
    dependencies: { supabaseConfigured },
  }
}
