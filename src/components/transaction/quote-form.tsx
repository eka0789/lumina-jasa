"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { AlertCircle, CheckCircle2, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

export function QuoteForm({ jobId, providerServiceId }: { jobId: string; providerServiceId: string }) {
  const router=useRouter(); const [amount,setAmount]=useState(0); const [duration,setDuration]=useState(120); const [message,setMessage]=useState(""); const [error,setError]=useState<string|null>(null); const [sent,setSent]=useState(false); const [busy,setBusy]=useState(false)
  async function submit(){ if(amount<=0||duration<30||message.trim().length<10)return setError("Lengkapi harga, durasi, dan pesan minimal 10 karakter."); setBusy(true);setError(null);const supabase=createClient();if(!supabase){setBusy(false);return}const {error:rpcError}=await supabase.rpc("submit_job_quote",{p_job_id:jobId,p_provider_service_id:providerServiceId,p_amount:amount,p_duration_minutes:duration,p_message:message,p_expires_at:new Date(Date.now()+48*3600_000).toISOString()});if(rpcError)setError("Penawaran belum dapat dikirim.");else{setSent(true);router.refresh()}setBusy(false)}
  if(sent)return <p role="status" className="flex items-center gap-2 text-sm font-semibold text-success"><CheckCircle2 className="size-4"/>Penawaran terkirim</p>
  return <div className="grid gap-3 rounded-lg border bg-muted/30 p-4 sm:grid-cols-2"><label className="space-y-1 text-sm font-semibold">Harga<input className="mt-1 min-h-11 w-full rounded-md border bg-background px-3" type="number" min={1} step={10000} value={amount||""} onChange={e=>setAmount(Number(e.target.value))}/></label><label className="space-y-1 text-sm font-semibold">Durasi (menit)<Input className="mt-1" type="number" min={30} value={duration} onChange={e=>setDuration(Number(e.target.value))}/></label><label className="space-y-1 text-sm font-semibold sm:col-span-2">Pesan<textarea className="mt-1 w-full rounded-md border bg-background px-3 py-2 font-normal" rows={3} value={message} onChange={e=>setMessage(e.target.value)}/></label>{error&&<p role="alert" className="flex gap-2 text-sm text-destructive sm:col-span-2"><AlertCircle className="size-4"/>{error}</p>}<Button className="sm:col-span-2" onClick={submit} disabled={busy}>{busy&&<LoaderCircle className="size-4 animate-spin"/>}Kirim penawaran</Button></div>
}
