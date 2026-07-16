import type { Metadata } from "next"
import Link from "next/link"
import { ArrowLeft, BadgeCheck, Filter, MapPin, Search, Sparkles, Star } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"

export const metadata: Metadata = { title: "Cari Jasa" }

const samples = [
  { initials: "BT", name: "Budi Teknik", category: "Perbaikan rumah", rating: "4,9", reviews: 128, distance: "2,1 km", price: "Rp200–350 rb", match: 92 },
  { initials: "SR", name: "Sejuk Refrigerasi", category: "AC & pendingin", rating: "4,8", reviews: 94, distance: "3,4 km", price: "Rp250–400 rb", match: 88 },
  { initials: "AP", name: "Andi Pratama", category: "Teknisi panggilan", rating: "4,8", reviews: 76, distance: "4,0 km", price: "Rp180–325 rb", match: 84 },
]

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string; kategori?: string }> }) {
  const params = await searchParams
  const query = params.q ?? params.kategori ?? ""
  return (
    <div className="min-h-screen"><SiteHeader /><main id="konten-utama" className="container py-10 sm:py-14">
      <Link href="/" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> Beranda</Link>
      <div className="mt-7 max-w-3xl"><Badge><Sparkles className="size-3.5" /> Pencarian cerdas</Badge><h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">Temukan ahli yang sesuai</h1><p className="mt-3 text-muted-foreground">Hasil contoh foundation. Data produksi akan berasal dari katalog terverifikasi dan pencocokan berbasis lokasi.</p></div>
      <form className="mt-8 flex max-w-3xl flex-col gap-3 rounded-lg border bg-card p-3 shadow-soft sm:flex-row" role="search">
        <label htmlFor="q" className="sr-only">Cari layanan</label><div className="relative flex-1"><Search className="absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-muted-foreground" /><Input id="q" name="q" defaultValue={query} className="pl-11" placeholder="Apa yang perlu dibantu?" /></div><button className={buttonVariants()} type="submit">Cari sekarang</button>
      </form>
      <div className="mt-10 grid gap-8 lg:grid-cols-[230px_1fr]">
        <aside className="hidden lg:block"><div className="sticky top-24 rounded-lg border bg-card p-5"><p className="flex items-center gap-2 font-semibold"><Filter className="size-4" /> Filter</p>{["Terverifikasi", "Tersedia hari ini", "Jarak < 5 km", "Rating 4,5+"].map((item) => <label key={item} className="mt-4 flex items-center gap-3 text-sm text-muted-foreground"><input type="checkbox" className="size-4 accent-[hsl(var(--primary))]" /> {item}</label>)}</div></aside>
        <section aria-labelledby="hasil-title"><div className="mb-5 flex items-end justify-between gap-4"><div><h2 id="hasil-title" className="text-xl font-bold">Rekomendasi di sekitar Anda</h2><p className="mt-1 text-sm text-muted-foreground">3 penyedia contoh · urut berdasarkan kecocokan</p></div><button className={cn(buttonVariants({ variant: "outline", size: "sm" }), "lg:hidden")}><Filter className="size-4" /> Filter</button></div>
          <div className="space-y-4">{samples.map((provider, index) => <Card key={provider.name} className={cn(index === 0 && "border-primary/35")}><CardContent className="p-5"><div className="flex flex-col gap-5 sm:flex-row sm:items-center"><div className="grid size-14 shrink-0 place-items-center rounded-full bg-secondary font-bold text-primary">{provider.initials}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold">{provider.name}</h3><BadgeCheck className="size-4 text-primary" aria-label="Terverifikasi" />{index === 0 && <Badge>Pilihan terbaik</Badge>}</div><p className="mt-1 text-sm text-muted-foreground">{provider.category}</p><div className="mt-3 flex flex-wrap gap-4 text-xs text-muted-foreground"><span className="inline-flex items-center gap-1"><Star className="size-3.5 fill-warning text-warning" /> {provider.rating} ({provider.reviews})</span><span className="inline-flex items-center gap-1"><MapPin className="size-3.5" /> {provider.distance}</span></div></div><div className="sm:text-right"><p className="text-sm font-bold text-primary">{provider.match}% cocok</p><p className="mt-1 font-semibold">{provider.price}</p><Link href="/masuk" className={cn(buttonVariants({ size: "sm" }), "mt-3 w-full sm:w-auto")}>Lihat profil</Link></div></div></CardContent></Card>)}</div>
        </section>
      </div>
    </main></div>
  )
}
