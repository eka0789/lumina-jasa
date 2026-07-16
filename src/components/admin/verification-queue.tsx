"use client"

import { useState } from "react"
import { AlertCircle, CheckCircle2, ExternalLink, LoaderCircle, XCircle } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { createClient } from "@/lib/supabase/client"

export type VerificationQueueItem = {
  id: string
  kind: string
  submittedAt: string
  provider: { name: string; slug: string; areas: string[]; radiusKm: number | null } | null
  document: { fileId: string; url: string; type: string; scanStatus: string } | null
}

export function VerificationQueue({ initialItems }: { initialItems: VerificationQueueItem[] }) {
  const [items, setItems] = useState(initialItems)
  const [reasons, setReasons] = useState<Record<string, string>>({})
  const [busyId, setBusyId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  async function decide(id: string, decision: "approved" | "rejected") {
    const reason = reasons[id]?.trim() ?? ""
    if (reason.length < 8) return setError("Alasan keputusan minimal 8 karakter.")
    setBusyId(id); setError(null); setMessage(null)
    const supabase = createClient()
    if (!supabase) { setBusyId(null); return setError("Supabase belum dikonfigurasi.") }
    const { error: reviewError } = await supabase.rpc("review_provider_verification", {
      verification_case_id: id, decision, decision_reason: reason, request_correlation_id: crypto.randomUUID(),
    })
    if (reviewError) {
      setError(reviewError.message.includes("aal2") ? "Sesi AAL2 diperlukan. Verifikasi ulang MFA lalu coba lagi." : "Keputusan belum tersimpan. Periksa akses dan coba lagi.")
    } else {
      setItems((current) => current.filter((item) => item.id !== id))
      setMessage(decision === "approved" ? "Penyedia disetujui dan sekarang tampil di katalog." : "Penyedia ditolak dengan alasan tercatat.")
    }
    setBusyId(null)
  }

  async function markScanClean(item: VerificationQueueItem) {
    const reason = reasons[item.id]?.trim() ?? ""
    if (!item.document || reason.length < 8) return setError("Catat alasan pemindaian minimal 8 karakter.")
    setBusyId(item.id); setError(null)
    const supabase = createClient()
    if (!supabase) { setBusyId(null); return setError("Supabase belum dikonfigurasi.") }
    const { error: scanError } = await supabase.rpc("record_compliance_document_scan", { compliance_file_id: item.document.fileId, scan_result: "clean", scan_reason: reason, request_correlation_id: crypto.randomUUID() })
    if (scanError) setError("Hasil pemindaian belum tersimpan.")
    else { setItems((current) => current.map((entry) => entry.id === item.id && entry.document ? { ...entry, document: { ...entry.document, scanStatus: "clean" } } : entry)); setMessage("Hasil pemindaian dokumen tercatat bersih.") }
    setBusyId(null)
  }

  if (items.length === 0) return <div className="rounded-lg border bg-card p-10 text-center"><CheckCircle2 className="mx-auto size-9 text-success" /><h2 className="mt-4 font-bold">Antrean bersih</h2><p className="mt-2 text-sm text-muted-foreground">Tidak ada kasus KYC/KYB yang menunggu tinjauan.</p></div>

  return <div className="space-y-5">
    {error && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="mt-0.5 size-4 shrink-0" />{error}</div>}
    {message && <div role="status" className="flex gap-2 rounded-md border border-success/20 bg-success/5 p-3 text-sm text-success"><CheckCircle2 className="mt-0.5 size-4 shrink-0" />{message}</div>}
    {items.map((item) => <article key={item.id} className="rounded-lg border bg-card p-5 shadow-soft">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div><div className="flex flex-wrap items-center gap-2"><h2 className="font-bold">{item.provider?.name ?? "Penyedia tanpa profil"}</h2><Badge variant="warning">{item.kind.toUpperCase()}</Badge></div><p className="mt-2 text-sm text-muted-foreground">/{item.provider?.slug} · Dikirim {new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(item.submittedAt))}</p><p className="mt-2 text-sm">Area: {item.provider?.areas.join(", ") || "Belum dicantumkan"}{item.provider?.radiusKm ? ` · radius ${item.provider.radiusKm} km` : ""}</p>
          {item.document ? <a href={item.document.url} target="_blank" rel="noreferrer" className="mt-3 inline-flex min-h-11 items-center gap-2 rounded-md border px-3 text-sm font-semibold text-primary hover:bg-accent"><ExternalLink className="size-4" />Buka dokumen {item.document.type.replaceAll("_", " ")} · scan {item.document.scanStatus}</a> : <p className="mt-3 text-sm font-semibold text-destructive">Dokumen verifikasi tidak tersedia.</p>}
        </div>
      </div>
      <div className="mt-5 space-y-2"><label htmlFor={`reason-${item.id}`} className="text-sm font-semibold">Alasan keputusan</label><textarea id={`reason-${item.id}`} rows={3} value={reasons[item.id] ?? ""} onChange={(event) => setReasons((current) => ({ ...current, [item.id]: event.target.value }))} className="w-full rounded-md border bg-background px-3 py-2 text-sm" placeholder="Catat bukti yang ditinjau dan dasar keputusan." /></div>
      <div className="mt-4 flex flex-col gap-2 sm:flex-row sm:justify-end">{item.document && item.document.scanStatus !== "clean" && <Button variant="outline" onClick={() => markScanClean(item)} disabled={busyId === item.id}>Catat scan bersih</Button>}<Button variant="destructive" onClick={() => decide(item.id, "rejected")} disabled={busyId === item.id}><XCircle className="size-4" />Tolak</Button><Button onClick={() => decide(item.id, "approved")} disabled={busyId === item.id || item.document?.scanStatus !== "clean"}>{busyId === item.id ? <LoaderCircle className="size-4 animate-spin motion-reduce:animate-none" /> : <CheckCircle2 className="size-4" />}Setujui</Button></div>
    </article>)}
  </div>
}
