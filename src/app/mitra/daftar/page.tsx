import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { ArrowLeft, ShieldCheck } from "lucide-react"
import { ProviderOnboardingForm } from "@/components/provider/onboarding-form"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { getCatalogServiceOptions } from "@/lib/catalog"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Pendaftaran Mitra" }
export const dynamic = "force-dynamic"

export default async function ProviderOnboardingPage() {
  if (!getPublicEnv()) return <main className="container py-16"><Card className="mx-auto max-w-xl"><CardHeader><CardTitle>Supabase belum dikonfigurasi</CardTitle><CardDescription>Lengkapi environment dari `.env.example` untuk menjalankan onboarding.</CardDescription></CardHeader></Card></main>
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk?next=/mitra/daftar")
  const services = await getCatalogServiceOptions()
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-3xl"><Link href="/mitra" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />Kembali</Link><div className="mt-8"><span className="inline-flex items-center gap-2 text-sm font-bold text-primary"><ShieldCheck className="size-4" />Onboarding penyedia</span><h1 className="mt-3 text-3xl font-bold tracking-tight sm:text-4xl">Siapkan profil layanan Anda</h1><p className="mt-3 max-w-2xl leading-7 text-muted-foreground">Data dikirim sebagai satu transaksi dan masuk antrean verifikasi manual. Anda tidak dapat mengaktifkan profil sendiri.</p></div><Card className="mt-8 shadow-float"><CardContent className="p-5 sm:p-8"><ProviderOnboardingForm services={services} /></CardContent></Card></div></main>
}
