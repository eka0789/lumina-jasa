import type { Metadata } from "next"
import { redirect } from "next/navigation"
import { AlertTriangle } from "lucide-react"
import { EmergencyJobForm } from "@/components/transaction/emergency-job-form"
import { Card, CardContent } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Permintaan Mendesak" }
export const dynamic = "force-dynamic"

export default async function EmergencyPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect("/masuk?next=/pesan/darurat")
  const { data } = await supabase.from("services").select("id,name").eq("status", "active").eq("emergency_enabled", true).order("name")
  const services = data ?? []
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-2xl"><span className="inline-flex items-center gap-2 text-sm font-bold text-warning-foreground"><AlertTriangle className="size-4" />Dispatch mendesak terbatas</span><h1 className="mt-3 text-3xl font-bold">Butuh penyedia secepatnya?</h1><p className="mt-3 text-muted-foreground">Permintaan dikirim ke maksimal lima penyedia terverifikasi berdasarkan kesiapan respons. Ketersediaan tidak dijamin.</p>{services.length === 0 ? <Card className="mt-8"><CardContent className="p-8 text-center text-muted-foreground">Belum ada layanan yang disetujui untuk dispatch mendesak.</CardContent></Card> : <Card className="mt-8"><CardContent className="p-5 sm:p-8"><EmergencyJobForm services={services} /></CardContent></Card>}</div></main>
}
