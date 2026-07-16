import type { Metadata } from "next"
import { redirect } from "next/navigation"
import { LaunchControls, type LaunchFlag, type LaunchMetrics } from "@/components/admin/launch-controls"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Kontrol Peluncuran" }
export const dynamic = "force-dynamic"
const emptyMetrics: LaunchMetrics = { activeBookings: 0, openDisputes: 0, pendingRefunds: 0, openModeration: 0, outboxBacklog: 0, aiFallback24h: 0 }

export default async function LaunchPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk?next=/admin/peluncuran")
  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
  const roleNames = (roles ?? []).map((item) => item.role)
  if (!roleNames.some((role) => ["support", "admin", "super_admin"].includes(role))) redirect("/")
  const [{ data: flagData }, { data: metricData }] = await Promise.all([
    supabase.from("platform_feature_flags").select("name,enabled,reason,updated_at").order("name"),
    supabase.rpc("get_launch_metrics"),
  ])
  const flags: LaunchFlag[] = (flagData ?? []).map((flag) => ({ name: flag.name, enabled: flag.enabled, reason: flag.reason, updatedAt: flag.updated_at }))
  const metrics = metricData && typeof metricData === "object" && !Array.isArray(metricData) ? metricData as unknown as LaunchMetrics : emptyMetrics
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-5xl"><h1 className="text-3xl font-bold">Kontrol peluncuran</h1><p className="mt-2 text-muted-foreground">Pantau antrean kritis dan hentikan alur berisiko tanpa redeploy.</p><div className="mt-8"><LaunchControls flags={flags} metrics={metrics} canManage={roleNames.some((role) => ["admin", "super_admin"].includes(role))} /></div></div></main>
}
