import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { BriefcaseBusiness, CalendarDays } from "lucide-react"
import { QuoteForm } from "@/components/transaction/quote-form"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"
import { formatRupiah } from "@/lib/utils"

export const metadata: Metadata={title:"Permintaan Masuk"}; export const dynamic="force-dynamic"
type RawMatch={id:string;provider_service_id:string;score:number|string;job:{id:string;title:string;description:string;requested_start:string;requested_end:string;budget_min:number;budget_max:number;status:string;service:{name:string}|null}|null}

export default async function ProviderRequestsPage(){
  if(!getPublicEnv())return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase=await createClient();const{data:{user}}=await supabase.auth.getUser();if(!user)redirect("/masuk?next=/mitra/permintaan")
  const{data:members}=await supabase.from("provider_members").select("provider_id").eq("user_id",user.id).eq("status","active");const providerIds=(members??[]).map(item=>item.provider_id);if(providerIds.length===0)redirect("/mitra/daftar")
  const{data,error}=await supabase.from("job_matches").select("id, provider_service_id, score, job:jobs(id,title,description,requested_start,requested_end,budget_min,budget_max,status,service:services(name))").in("provider_id",providerIds).in("status",["invited","viewed"]).order("created_at",{ascending:false});if(error)throw new Error(error.message)
  const matches=(data??[]) as unknown as RawMatch[]
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-4xl"><div className="flex items-end justify-between gap-4"><div><span className="inline-flex items-center gap-2 text-sm font-bold text-primary"><BriefcaseBusiness className="size-4"/>Ruang kerja mitra</span><h1 className="mt-3 text-3xl font-bold">Permintaan yang cocok</h1><p className="mt-2 text-muted-foreground">Tinjau kebutuhan dan kirim snapshot penawaran yang jelas.</p></div><Link href="/mitra" className="text-sm font-semibold text-primary hover:underline">Profil mitra</Link></div><div className="mt-8 space-y-5">{matches.length===0?<Card><CardContent className="p-8 text-center text-muted-foreground">Belum ada permintaan yang cocok.</CardContent></Card>:matches.map(match=>match.job&&<Card key={match.id}><CardContent className="p-5 sm:p-6"><div className="flex flex-wrap items-start justify-between gap-3"><div><Badge>{match.job.service?.name??"Layanan"}</Badge><h2 className="mt-3 text-lg font-bold">{match.job.title}</h2></div><span className="text-sm font-bold text-primary">{Math.round(Number(match.score)*100)}% cocok</span></div><p className="mt-3 leading-6 text-muted-foreground">{match.job.description}</p><div className="my-5 flex flex-wrap gap-4 border-y py-4 text-sm"><span className="inline-flex items-center gap-2"><CalendarDays className="size-4 text-primary"/>{new Intl.DateTimeFormat("id-ID",{dateStyle:"medium",timeStyle:"short"}).format(new Date(match.job.requested_start))}</span><span>Anggaran {formatRupiah(match.job.budget_min)}–{formatRupiah(match.job.budget_max)}</span></div><QuoteForm jobId={match.job.id} providerServiceId={match.provider_service_id}/></CardContent></Card>)}</div></div></main>
}
