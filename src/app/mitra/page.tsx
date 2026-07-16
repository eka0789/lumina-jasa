import type { Metadata } from "next"
import Link from "next/link"
import { ArrowRight, BadgeCheck, BarChart3, CalendarDays, Check, WalletCards } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { cn } from "@/lib/utils"

export const metadata: Metadata = { title: "Jadi Mitra" }

export default function PartnerPage() {
  const features = [
    { icon: CalendarDays, title: "Jadwal lebih rapi", text: "Atur waktu, area layanan, dan kapasitas tanpa percakapan berulang." },
    { icon: WalletCards, title: "Pembayaran terlacak", text: "Lihat nilai pekerjaan, potongan, status, dan riwayat pembayaran." },
    { icon: BarChart3, title: "Kinerja yang terukur", text: "Pahami respons, penyelesaian, ulasan, dan peluang peningkatan." },
  ]
  return <div className="min-h-screen"><SiteHeader /><main id="konten-utama">
    <section className="border-b bg-secondary/45"><div className="container grid items-center gap-12 py-16 lg:grid-cols-2 lg:py-24"><div><Badge><BadgeCheck className="size-3.5" />Mitra terverifikasi</Badge><h1 className="mt-6 text-balance text-4xl font-bold leading-tight tracking-tight sm:text-5xl">Bangun reputasi. Temukan pekerjaan yang tepat.</h1><p className="mt-5 max-w-xl text-lg leading-8 text-muted-foreground">Lumina Jasa membantu profesional dan bisnis jasa mengelola layanan, permintaan, jadwal, komunikasi, dan pendapatan dalam satu alur.</p><div className="mt-8 flex flex-col gap-3 sm:flex-row"><Link href="/mitra/daftar" className={cn(buttonVariants({ size: "lg" }))}>Mulai pendaftaran <ArrowRight className="size-4" /></Link><a href="mailto:mitra@luminajasa.id" className={cn(buttonVariants({ variant: "outline", size: "lg" }))}>Hubungi tim mitra</a></div></div><div className="rounded-[2rem] bg-[hsl(var(--teal-900))] p-7 text-white shadow-float sm:p-10"><p className="text-sm font-bold uppercase tracking-[0.18em] text-[hsl(var(--teal-100))]">Tahap verifikasi</p><ol className="mt-8 space-y-6">{["Lengkapi profil dan layanan", "Verifikasi identitas atau bisnis", "Atur area dan ketersediaan", "Tinjauan lalu mulai menerima permintaan"].map((step, index) => <li key={step} className="flex items-center gap-4"><span className="grid size-9 shrink-0 place-items-center rounded-full border border-white/20 bg-white/10 text-sm font-bold">{index + 1}</span><span className="font-medium">{step}</span>{index < 3 ? null : <Check className="ml-auto size-5 text-[hsl(var(--teal-100))]" />}</li>)}</ol><p className="mt-8 rounded-lg border border-white/10 bg-white/5 p-4 text-sm leading-6 text-white/70">Aktivasi bergantung pada kelengkapan dan hasil verifikasi. Keputusan yang membatasi akses memiliki alasan dan jalur tinjauan.</p></div></div></section>
    <section className="container py-20"><div className="mx-auto max-w-2xl text-center"><h2 className="text-3xl font-bold tracking-tight">Lebih banyak waktu untuk keahlian Anda</h2><p className="mt-4 text-muted-foreground">Operasional rutin dibuat lebih jelas agar Anda dapat fokus memberi hasil terbaik.</p></div><div className="mt-10 grid gap-5 md:grid-cols-3">{features.map(({ icon: Icon, title, text }) => <Card key={title}><CardHeader><span className="mb-5 grid size-11 place-items-center rounded-lg bg-secondary text-primary"><Icon className="size-5" /></span><CardTitle>{title}</CardTitle><CardDescription>{text}</CardDescription></CardHeader></Card>)}</div></section>
  </main></div>
}
