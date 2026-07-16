import type { Metadata } from "next"
import { redirect } from "next/navigation"
import { ScaleOperations, type ForecastItem, type FraudCaseItem, type ModelItem } from "@/components/admin/scale-operations"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Operasi Skala" }
export const dynamic = "force-dynamic"

export default async function ScalePage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect("/masuk?next=/admin/skala")
  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null); if (!(roles ?? []).some((item) => ["support", "compliance", "admin", "super_admin"].includes(item.role))) redirect("/")
  const [{ data: caseData }, { data: forecastData }, { data: modelData }, { data: serviceData }] = await Promise.all([supabase.from("fraud_cases").select("id,subject_user_id,risk_score,severity,status").in("status", ["open", "reviewing", "appealed"]).order("created_at"), supabase.from("demand_forecasts").select("id,service_id,p10,p50,p90,horizon_end").order("created_at", { ascending: false }).limit(12), supabase.from("ranking_model_versions").select("id,name,status,traffic_percent").order("created_at", { ascending: false }), supabase.from("services").select("id,name").eq("status", "active").order("name")])
  const cases: FraudCaseItem[] = (caseData ?? []).map((item) => ({ id: item.id, userId: item.subject_user_id ?? "-", risk: Number(item.risk_score), severity: item.severity, status: item.status })); const forecasts: ForecastItem[] = (forecastData ?? []).map((item) => ({ id: item.id, serviceId: item.service_id, p10: Number(item.p10), p50: Number(item.p50), p90: Number(item.p90), horizonEnd: item.horizon_end })); const models: ModelItem[] = (modelData ?? []).map((item) => ({ id: item.id, name: item.name, status: item.status, traffic: item.traffic_percent }))
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-5xl"><h1 className="text-3xl font-bold">Operasi skala</h1><p className="mt-2 text-muted-foreground">Emergency dispatch, fraud review, forecast, dan registry ranking dengan keputusan manusia.</p><div className="mt-8"><ScaleOperations cases={cases} forecasts={forecasts} models={models} services={serviceData ?? []} /></div></div></main>
}
