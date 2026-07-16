"use client"

import { useState } from "react"
import { AlertCircle, CheckCircle2, ShieldCheck } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

export type ModerationItem = { id: string; subjectType: string; labels: string[]; confidence: number; createdAt: string }

export function ModerationQueue({ items }: { items: ModerationItem[] }) {
  const [reasons, setReasons] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  async function decide(id: string, decision: "allowed" | "blocked") {
    setError(null); setMessage(null)
    const supabase = createClient(); if (!supabase) return
    const { error: rpcError } = await supabase.rpc("resolve_moderation_case", { p_case_id: id, p_decision: decision, p_reason: reasons[id] ?? "", p_correlation_id: crypto.randomUUID() })
    if (rpcError) setError("Keputusan ditolak. Pastikan AAL2, peran moderator, dan alasan valid.")
    else { setMessage("Keputusan moderasi disimpan dalam audit log."); window.location.reload() }
  }
  return <div className="space-y-5">{error && <p role="alert" className="flex gap-2 text-sm text-destructive"><AlertCircle className="size-4" />{error}</p>}{message && <p role="status" className="flex gap-2 text-sm text-success"><CheckCircle2 className="size-4" />{message}</p>}{items.length === 0 ? <div className="rounded-lg border p-8 text-center"><ShieldCheck className="mx-auto size-8 text-success" /><p className="mt-3 font-semibold">Tidak ada kasus terbuka</p></div> : items.map((item) => <article key={item.id} className="space-y-4 rounded-lg border bg-card p-5"><div className="flex flex-wrap items-center justify-between gap-3"><div><h2 className="font-bold capitalize">{item.subjectType}</h2><p className="mt-1 text-xs text-muted-foreground">{new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(item.createdAt))}</p></div><Badge variant="warning">{Math.round(item.confidence * 100)}% sinyal</Badge></div><div className="flex flex-wrap gap-2">{item.labels.map((label) => <Badge key={label} variant="outline">{label.replaceAll("_", " ")}</Badge>)}</div><Input placeholder="Alasan keputusan manusia" value={reasons[item.id] ?? ""} onChange={(event) => setReasons((current) => ({ ...current, [item.id]: event.target.value }))} /><div className="flex gap-2"><Button variant="destructive" size="sm" onClick={() => decide(item.id, "blocked")}>Blokir</Button><Button size="sm" onClick={() => decide(item.id, "allowed")}>Izinkan</Button></div></article>)}</div>
}
