"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { AlertTriangle, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

type Service = { id: string; name: string }

export function EmergencyJobForm({ services }: { services: Service[] }) {
  const router = useRouter(); const [serviceId, setServiceId] = useState(services[0]?.id ?? ""); const [title, setTitle] = useState(""); const [description, setDescription] = useState(""); const [budget, setBudget] = useState(500000); const [confirmed, setConfirmed] = useState(false); const [busy, setBusy] = useState(false); const [error, setError] = useState<string | null>(null)
  async function submit(event: React.FormEvent) {
    event.preventDefault(); setError(null)
    if (!confirmed) return setError("Konfirmasi bahwa ini bukan keadaan yang mengancam nyawa.")
    setBusy(true); const supabase = createClient(); if (!supabase) { setBusy(false); return }
    const { data, error: rpcError } = await supabase.rpc("submit_emergency_job_request", { p_service_id: serviceId, p_title: title, p_description: description, p_budget_max: budget, p_safety_confirmed: confirmed, p_idempotency_key: crypto.randomUUID() })
    if (rpcError || !data) setError("Dispatch darurat tidak tersedia untuk detail atau layanan ini.")
    else { router.push(`/permintaan/${data}`); router.refresh() }
    setBusy(false)
  }
  return <form onSubmit={submit} className="space-y-5"><label className="block text-sm font-semibold">Layanan<select className="mt-2 min-h-11 w-full rounded-md border bg-background px-3" value={serviceId} onChange={(event) => setServiceId(event.target.value)}>{services.map((service) => <option key={service.id} value={service.id}>{service.name}</option>)}</select></label><label className="block text-sm font-semibold">Masalah mendesak<Input className="mt-2" value={title} onChange={(event) => setTitle(event.target.value)} /></label><label className="block text-sm font-semibold">Kondisi dan akses lokasi<textarea className="mt-2 w-full rounded-md border bg-background px-3 py-2 font-normal" rows={5} value={description} onChange={(event) => setDescription(event.target.value)} /></label><label className="block text-sm font-semibold">Anggaran maksimum<Input className="mt-2" type="number" min={1} value={budget} onChange={(event) => setBudget(Number(event.target.value))} /></label><label className="flex gap-3 rounded-lg border border-warning/30 bg-warning/10 p-4 text-sm"><input type="checkbox" className="mt-1 size-4" checked={confirmed} onChange={(event) => setConfirmed(event.target.checked)} /><span>Saya memahami layanan ini bukan pengganti polisi, pemadam, ambulans, atau otoritas darurat. Tidak ada ancaman langsung terhadap nyawa atau keselamatan.</span></label>{error && <p role="alert" className="flex gap-2 text-sm text-destructive"><AlertTriangle className="size-4" />{error}</p>}<Button className="w-full" size="lg" disabled={busy || services.length === 0}>{busy && <LoaderCircle className="size-4 animate-spin" />}Cari penyedia siaga</Button></form>
}
