"use client"

import { useState } from "react"
import { AlertTriangle, CheckCircle2, LoaderCircle, Power } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

export type LaunchFlag = { name: string; enabled: boolean; reason: string; updatedAt: string }
export type LaunchMetrics = { activeBookings: number; openDisputes: number; pendingRefunds: number; openModeration: number; outboxBacklog: number; aiFallback24h: number }

const labels: Record<string, string> = { booking_intake: "Permintaan baru", payment_capture: "Capture pembayaran", payout_release: "Pencairan penyedia", ai_intake: "Asisten intake", tracking_publish: "Publikasi lokasi" }
const metricLabels: Array<[keyof LaunchMetrics, string]> = [["activeBookings", "Booking aktif"], ["openDisputes", "Sengketa terbuka"], ["pendingRefunds", "Refund menunggu"], ["openModeration", "Moderasi terbuka"], ["outboxBacklog", "Outbox tertunda"], ["aiFallback24h", "Fallback AI 24 jam"]]

export function LaunchControls({ flags, metrics, canManage }: { flags: LaunchFlag[]; metrics: LaunchMetrics; canManage: boolean }) {
  const [reasons, setReasons] = useState<Record<string, string>>({})
  const [busy, setBusy] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function toggle(flag: LaunchFlag) {
    setBusy(flag.name); setError(null)
    const supabase = createClient(); if (!supabase) { setBusy(null); return }
    const { error: rpcError } = await supabase.rpc("set_platform_feature_flag", { p_name: flag.name, p_enabled: !flag.enabled, p_reason: reasons[flag.name] ?? "", p_correlation_id: crypto.randomUUID() })
    if (rpcError) setError("Perubahan ditolak. Gunakan AAL2, peran admin, dan alasan minimal 10 karakter.")
    else window.location.reload()
    setBusy(null)
  }

  return <div className="space-y-10">
    {error && <p role="alert" className="flex gap-2 rounded-lg border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertTriangle className="size-4" />{error}</p>}
    <section aria-labelledby="signals-title"><h2 id="signals-title" className="text-xl font-bold">Sinyal operasional</h2><div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{metricLabels.map(([key, label]) => <div key={key} className="rounded-lg border bg-card p-4"><p className="text-sm text-muted-foreground">{label}</p><p className="mt-1 text-2xl font-bold">{metrics[key].toLocaleString("id-ID")}</p></div>)}</div></section>
    <section aria-labelledby="controls-title"><div><h2 id="controls-title" className="text-xl font-bold">Kill switches</h2><p className="mt-1 text-sm text-muted-foreground">Perubahan langsung berlaku di database dan selalu dicatat dalam audit log.</p></div><div className="mt-4 space-y-4">{flags.map((flag) => <article key={flag.name} className="rounded-lg border bg-card p-5"><div className="flex flex-wrap items-center justify-between gap-3"><div><h3 className="font-bold">{labels[flag.name] ?? flag.name}</h3><p className="mt-1 text-xs text-muted-foreground">{flag.reason}</p></div><Badge variant={flag.enabled ? "success" : "warning"}>{flag.enabled ? <CheckCircle2 className="size-3" /> : <Power className="size-3" />}{flag.enabled ? "Aktif" : "Dihentikan"}</Badge></div>{canManage && <div className="mt-4 flex flex-col gap-2 sm:flex-row"><Input aria-label={`Alasan perubahan ${labels[flag.name] ?? flag.name}`} placeholder="Alasan operasional" value={reasons[flag.name] ?? ""} onChange={(event) => setReasons((current) => ({ ...current, [flag.name]: event.target.value }))} /><Button variant={flag.enabled ? "destructive" : "default"} onClick={() => toggle(flag)} disabled={busy === flag.name}>{busy === flag.name && <LoaderCircle className="size-4 animate-spin" />}{flag.enabled ? "Hentikan" : "Aktifkan"}</Button></div>}</article>)}</div></section>
  </div>
}
