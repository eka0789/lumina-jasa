import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import { ArrowLeft, BadgeCheck, BriefcaseBusiness, CalendarDays, MapPin, MessageCircleMore, ShieldCheck, Star } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { getCatalogProvider } from "@/lib/catalog"
import { cn, formatRupiah } from "@/lib/utils"

const dayNames = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const provider = await getCatalogProvider((await params).slug)
  return { title: provider?.name ?? "Penyedia tidak ditemukan", description: provider?.bio }
}

export default async function ProviderProfilePage({ params }: { params: Promise<{ slug: string }> }) {
  const provider = await getCatalogProvider((await params).slug)
  if (!provider) notFound()

  return <div className="min-h-screen"><SiteHeader /><main id="konten-utama">
    <section className="border-b bg-secondary/40"><div className="container py-10 sm:py-14"><Link href="/cari" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />Kembali ke katalog</Link><div className="mt-8 flex flex-col gap-6 sm:flex-row sm:items-center"><div className="grid size-24 shrink-0 place-items-center rounded-2xl bg-primary text-2xl font-black text-primary-foreground shadow-soft">{provider.initials}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-3"><h1 className="text-3xl font-bold tracking-tight sm:text-4xl">{provider.name}</h1><Badge variant="success"><BadgeCheck className="size-3.5" />Terverifikasi</Badge></div><p className="mt-3 max-w-2xl leading-7 text-muted-foreground">{provider.bio}</p><div className="mt-4 flex flex-wrap gap-5 text-sm"><span className="inline-flex items-center gap-1.5"><Star className="size-4 fill-warning text-warning" /><strong>{provider.rating.toLocaleString("id-ID", { minimumFractionDigits: 1 })}</strong> ({provider.reviewCount} ulasan)</span><span className="inline-flex items-center gap-1.5"><BriefcaseBusiness className="size-4 text-primary" />{provider.completedJobs} pekerjaan</span><span className="inline-flex items-center gap-1.5"><MessageCircleMore className="size-4 text-primary" />{provider.responseRate}% respons</span></div></div></div></div></section>
    <div className="container grid gap-8 py-10 lg:grid-cols-[1fr_320px] lg:py-14"><div className="space-y-8"><section aria-labelledby="layanan-title"><h2 id="layanan-title" className="text-2xl font-bold">Layanan</h2><div className="mt-5 grid gap-4">{provider.services.map((service) => <Card key={`${service.name}-${service.title}`}><CardContent className="flex flex-col justify-between gap-4 p-5 sm:flex-row sm:items-center"><div><Badge variant="secondary">{service.category}</Badge><h3 className="mt-3 font-bold">{service.title}</h3><p className="mt-1 text-sm text-muted-foreground">{service.name}</p></div><div className="sm:text-right"><p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{service.pricingType === "fixed" ? "Harga tetap" : "Harga awal"}</p><p className="mt-1 text-lg font-bold">{service.basePrice ? formatRupiah(service.basePrice) : "Minta penawaran"}</p></div></CardContent></Card>)}</div></section><section aria-labelledby="jadwal-title"><h2 id="jadwal-title" className="text-2xl font-bold">Ketersediaan reguler</h2><div className="mt-5 grid gap-3 sm:grid-cols-2">{provider.availability.map((slot) => <div key={`${slot.weekday}-${slot.startsAt}`} className="flex items-center gap-3 rounded-lg border bg-card p-4"><CalendarDays className="size-5 text-primary" /><span><strong className="block text-sm">{dayNames[slot.weekday]}</strong><span className="text-sm text-muted-foreground">{slot.startsAt}–{slot.endsAt} WIB</span></span></div>)}</div></section></div>
      <aside><Card className="sticky top-24"><CardHeader><CardTitle>Area layanan</CardTitle><CardDescription>Konfirmasi alamat lengkap sebelum membuat pesanan.</CardDescription></CardHeader><CardContent className="space-y-5"><div className="space-y-3">{provider.areas.map((area) => <div key={area} className="flex items-center gap-2 text-sm"><MapPin className="size-4 text-primary" />{area}</div>)}{provider.radiusKm && <p className="text-xs text-muted-foreground">Radius operasional hingga {provider.radiusKm} km.</p>}</div><div className="rounded-lg border border-primary/15 bg-primary/5 p-4 text-sm"><ShieldCheck className="mb-2 size-5 text-primary" />Identitas atau badan usaha telah ditinjau. Status dapat berubah jika masa berlaku dokumen berakhir.</div><Link href="/masuk" className={cn(buttonVariants(), "w-full")}>Masuk untuk meminta jasa</Link></CardContent></Card></aside>
    </div>
  </main></div>
}
