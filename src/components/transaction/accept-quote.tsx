"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { AlertCircle, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

export function AcceptQuote({quoteId,defaultSchedule}:{quoteId:string;defaultSchedule:string}){const router=useRouter();const[schedule,setSchedule]=useState(defaultSchedule);const[busy,setBusy]=useState(false);const[error,setError]=useState<string|null>(null);async function accept(){setBusy(true);setError(null);const supabase=createClient();if(!supabase){setBusy(false);return}const{data,error:rpcError}=await supabase.rpc("accept_quote_and_create_booking",{p_quote_id:quoteId,p_scheduled_start:new Date(schedule).toISOString(),p_idempotency_key:crypto.randomUUID()});if(rpcError||!data)setError(rpcError?.code==="23P01"?"Jadwal baru saja terisi. Pilih waktu lain.":"Booking belum dapat dibuat.");else router.push(`/pesanan/${data}/bayar`);setBusy(false)}return <div className="mt-4 space-y-3"><label className="block text-sm font-semibold">Jadwal pilihan<Input className="mt-2" type="datetime-local" value={schedule} onChange={e=>setSchedule(e.target.value)}/></label>{error&&<p role="alert" className="flex gap-2 text-sm text-destructive"><AlertCircle className="size-4"/>{error}</p>}<Button className="w-full" onClick={accept} disabled={busy||!schedule}>{busy&&<LoaderCircle className="size-4 animate-spin"/>}Pilih dan lanjut bayar</Button></div>}
