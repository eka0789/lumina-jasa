import type { Metadata } from "next"
import { redirect } from "next/navigation"
import Link from "next/link"
import { ClipboardList } from "lucide-react"
import { JobRequestForm } from "@/components/transaction/job-request-form"
import { Card, CardContent } from "@/components/ui/card"
import { getCatalogServiceOptions } from "@/lib/catalog"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Buat Permintaan Jasa" }
export const dynamic = "force-dynamic"

export default async function CreateJobPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) redirect("/masuk?next=/pesan")
  const services=await getCatalogServiceOptions()
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-2xl"><span className="inline-flex items-center gap-2 text-sm font-bold text-primary"><ClipboardList className="size-4" />Permintaan terstruktur</span><h1 className="mt-3 text-3xl font-bold tracking-tight">Ceritakan kebutuhan Anda</h1><p className="mt-3 text-muted-foreground">Masukkan jendela jadwal dan anggaran. Penyedia yang sesuai dapat mengirim penawaran.</p><p className="mt-3 text-sm">Kebutuhan mendesak yang bukan keadaan mengancam nyawa? <Link href="/pesan/darurat" className="font-semibold text-primary hover:underline">Gunakan dispatch terbatas</Link>.</p><Card className="mt-8 shadow-float"><CardContent className="p-5 sm:p-8"><JobRequestForm services={services}/></CardContent></Card></div></main>
}
