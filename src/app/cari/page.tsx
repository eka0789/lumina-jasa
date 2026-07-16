import type { Metadata } from "next"
import Link from "next/link"
import { ArrowLeft, BadgeCheck, Filter, MapPin, Search, Sparkles, Star } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { getCatalogProviders } from "@/lib/catalog"
import { rankProviders } from "@/lib/ai/ranking"
import { cn, formatRupiah } from "@/lib/utils"

export const metadata: Metadata = { title: "Cari Jasa" }

type SearchParams = { q?: string; kategori?: string; area?: string; harga?: string }

export default async function SearchPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams
  const query = params.q ?? params.kategori ?? ""
  let providers = await getCatalogProviders(query)
  if (params.area) providers = providers.filter((provider) => provider.areas.some((area) => area.toLocaleLowerCase("id-ID").includes(params.area!.toLocaleLowerCase("id-ID"))))
  if (params.harga === "250") providers = providers.filter((provider) => provider.services.some((service) => service.basePrice !== null && service.basePrice <= 250000))
  const rankedProviders = rankProviders(providers, query, params.area)

  return (
    <div className="min-h-screen"><SiteHeader /><main id="konten-utama" className="container py-10 sm:py-14">
      <Link href="/" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />Beranda</Link>
      <div className="mt-7 max-w-3xl"><Badge><Sparkles className="size-3.5" />Katalog terverifikasi</Badge><h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">Temukan ahli yang sesuai</h1><p className="mt-3 text-muted-foreground">Bandingkan layanan, area, reputasi, dan harga awal penyedia yang telah lolos verifikasi.</p></div>
      <form className="mt-8 flex max-w-4xl flex-col gap-3 rounded-lg border bg-card p-3 shadow-soft sm:flex-row" role="search">
        <label htmlFor="q" className="sr-only">Cari layanan atau penyedia</label><div className="relative flex-1"><Search className="absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-muted-foreground" /><Input id="q" name="q" defaultValue={query} className="pl-11" placeholder="Layanan, masalah, atau nama penyedia" /></div>
        <label htmlFor="area" className="sr-only">Area layanan</label><Input id="area" name="area" defaultValue={params.area} className="sm:max-w-52" placeholder="Kota atau area" />
        <button className={buttonVariants()} type="submit">Cari sekarang</button>
      </form>
      <div className="mt-10 grid gap-8 lg:grid-cols-[230px_1fr]">
        <aside><form className="rounded-lg border bg-card p-5"><input type="hidden" name="q" value={query} /><input type="hidden" name="area" value={params.area ?? ""} /><p className="flex items-center gap-2 font-semibold"><Filter className="size-4" />Filter</p><fieldset className="mt-5 space-y-3"><legend className="text-sm font-semibold">Harga awal</legend><label className="flex items-center gap-3 text-sm text-muted-foreground"><input type="radio" name="harga" value="" defaultChecked={!params.harga} className="size-4 accent-[hsl(var(--primary))]" />Semua harga</label><label className="flex items-center gap-3 text-sm text-muted-foreground"><input type="radio" name="harga" value="250" defaultChecked={params.harga === "250"} className="size-4 accent-[hsl(var(--primary))]" />Maks. Rp250 ribu</label></fieldset><button className={cn(buttonVariants({ variant: "outline", size: "sm" }), "mt-5 w-full")} type="submit">Terapkan filter</button></form></aside>
        <section aria-labelledby="hasil-title"><div className="mb-5 flex items-end justify-between gap-4"><div><h2 id="hasil-title" className="text-xl font-bold">Hasil katalog</h2><p className="mt-1 text-sm text-muted-foreground">{providers.length} penyedia terverifikasi ditemukan</p></div></div>
          {providers.length === 0 ? <Card><CardContent className="p-8 text-center"><Search className="mx-auto size-8 text-muted-foreground" /><h3 className="mt-4 font-bold">Belum ada hasil yang cocok</h3><p className="mt-2 text-sm text-muted-foreground">Coba istilah layanan atau area yang lebih luas.</p><Link href="/cari" className={cn(buttonVariants({ variant: "outline", size: "sm" }), "mt-5")}>Hapus filter</Link></CardContent></Card> :
          <div className="space-y-4">{rankedProviders.map(({ provider, reasons }, index) => { const primaryService = provider.services[0]; return <Card key={provider.id} className={cn(index === 0 && "border-primary/35")}><CardContent className="p-5"><div className="flex flex-col gap-5 sm:flex-row sm:items-center"><div className="grid size-14 shrink-0 place-items-center rounded-full bg-secondary font-bold text-primary">{provider.initials}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold">{provider.name}</h3><BadgeCheck className="size-4 text-primary" aria-label="Terverifikasi" />{index === 0 && <Badge>Rekomendasi teratas</Badge>}</div><p className="mt-1 text-sm text-muted-foreground">{primaryService?.category ?? "Layanan profesional"} · {primaryService?.title}</p><div className="mt-3 flex flex-wrap gap-4 text-xs text-muted-foreground"><span className="inline-flex items-center gap-1"><Star className="size-3.5 fill-warning text-warning" />{provider.rating.toLocaleString("id-ID", { minimumFractionDigits: 1 })} ({provider.reviewCount})</span><span className="inline-flex items-center gap-1"><MapPin className="size-3.5" />{provider.areas.join(", ") || `Radius ${provider.radiusKm ?? "—"} km`}</span></div><ul className="mt-3 flex flex-wrap gap-2" aria-label="Alasan peringkat">{reasons.map((reason) => <li key={reason} className="rounded-full bg-muted px-2.5 py-1 text-xs text-muted-foreground">{reason}</li>)}</ul></div><div className="sm:text-right"><p className="text-sm font-bold text-primary">{provider.responseRate}% respons</p><p className="mt-1 font-semibold">{primaryService?.basePrice ? `Mulai ${formatRupiah(primaryService.basePrice)}` : "Minta penawaran"}</p><Link href={`/penyedia/${provider.slug}`} className={cn(buttonVariants({ size: "sm" }), "mt-3 w-full sm:w-auto")}>Lihat profil</Link></div></div></CardContent></Card> })}</div>}
        </section>
      </div>
    </main></div>
  )
}
