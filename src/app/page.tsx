import Link from "next/link"
import {
  ArrowRight, BadgeCheck, Bolt, Bot, BriefcaseBusiness, CalendarCheck2,
  Camera, Check, ChevronRight, CircleDollarSign, Clock3, Hammer, HeartHandshake,
  Home, MapPin, MessageCircleMore, Search, ShieldCheck, Sparkles, Star, Wrench,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { cn, formatRupiah } from "@/lib/utils"

const categories = [
  { name: "Perbaikan rumah", description: "Pipa, listrik, atap", icon: Wrench },
  { name: "Konstruksi", description: "Renovasi & bangun", icon: Hammer },
  { name: "Bisnis", description: "Operasional IKM", icon: BriefcaseBusiness },
  { name: "Kebersihan", description: "Rumah & kantor", icon: Home },
  { name: "Acara", description: "Vendor & produksi", icon: CalendarCheck2 },
  { name: "Jasa digital", description: "Desain & teknologi", icon: Bot },
]

const steps = [
  { number: "01", title: "Ceritakan kebutuhan", description: "Tulis masalah dengan bahasa sehari-hari dan tambahkan foto bila perlu.", icon: MessageCircleMore },
  { number: "02", title: "Bandingkan rekomendasi", description: "Lihat penyedia yang cocok, estimasi, ulasan, dan alasan rekomendasi.", icon: Search },
  { number: "03", title: "Pesan dengan tenang", description: "Jadwal, komunikasi, bukti pekerjaan, dan pembayaran ada dalam satu alur.", icon: ShieldCheck },
]

export default function HomePage() {
  return (
    <div className="min-h-screen overflow-hidden">

      <main id="konten-utama">
        <section className="relative isolate border-b">
          <div className="absolute inset-0 -z-20 bg-grid mask-fade" aria-hidden="true" />
          <div className="absolute -left-32 top-24 -z-10 size-96 rounded-full bg-primary/10 blur-3xl" aria-hidden="true" />
          <div className="absolute -right-24 top-8 -z-10 size-80 rounded-full bg-warning/10 blur-3xl" aria-hidden="true" />
          <div className="container grid min-h-[720px] items-center gap-14 py-16 lg:grid-cols-[1.05fr_.95fr] lg:py-24">
            <div className="max-w-2xl animate-fade-up">
              <Badge variant="outline" className="mb-6 border-primary/20 bg-primary/5 text-primary">
                <Sparkles className="size-3.5" aria-hidden="true" /> Marketplace jasa berbantuan AI
              </Badge>
              <h1 className="text-balance text-4xl font-bold leading-[1.08] tracking-[-0.045em] sm:text-5xl lg:text-6xl">
                Masalah selesai. <span className="text-primary">Tanpa menebak</span> siapa ahlinya.
              </h1>
              <p className="mt-6 max-w-xl text-balance text-lg leading-8 text-muted-foreground sm:text-xl">
                Ceritakan kebutuhan Anda. Lumina membantu menemukan penyedia terverifikasi, memperkirakan biaya, dan menjaga proses tetap transparan.
              </p>
              <form action="/cari" className="mt-8 flex max-w-xl flex-col gap-3 rounded-lg border bg-card p-2.5 shadow-float sm:flex-row" role="search">
                <label htmlFor="q" className="sr-only">Layanan atau masalah yang ingin diselesaikan</label>
                <div className="relative min-w-0 flex-1">
                  <Search className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
                  <Input id="q" name="q" className="border-0 bg-transparent pl-11 shadow-none focus-visible:ring-0" placeholder="Contoh: AC tidak dingin sejak kemarin" />
                </div>
                <button className={cn(buttonVariants({ size: "lg" }), "shrink-0")} type="submit">
                  Temukan ahli <ArrowRight className="size-4" aria-hidden="true" />
                </button>
              </form>
              <div className="mt-6 flex flex-wrap gap-x-6 gap-y-3 text-sm text-muted-foreground" aria-label="Keunggulan layanan">
                <span className="inline-flex items-center gap-2"><BadgeCheck className="size-4 text-primary" /> Penyedia diverifikasi</span>
                <span className="inline-flex items-center gap-2"><CircleDollarSign className="size-4 text-primary" /> Biaya transparan</span>
                <span className="inline-flex items-center gap-2"><ShieldCheck className="size-4 text-primary" /> Alur pembayaran terlindungi</span>
              </div>
            </div>

            <div className="relative mx-auto w-full max-w-xl lg:mx-0 lg:justify-self-end" aria-label="Contoh rekomendasi penyedia">
              <div className="absolute inset-x-10 -top-5 h-28 rounded-full bg-primary/15 blur-3xl" aria-hidden="true" />
              <Card className="relative overflow-hidden border-primary/15 bg-card/95 shadow-float backdrop-blur">
                <div className="flex items-center justify-between border-b bg-secondary/60 px-5 py-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.16em] text-primary">Smart Match</p>
                    <p className="mt-1 font-semibold">3 ahli cocok di sekitar Anda</p>
                  </div>
                  <Badge variant="success"><Bolt className="size-3" /> 1,8 detik</Badge>
                </div>
                <CardContent className="space-y-3 p-4 sm:p-5">
                  <div className="rounded-lg border border-primary/30 bg-primary/[0.035] p-4">
                    <div className="flex gap-3">
                      <div className="grid size-12 shrink-0 place-items-center rounded-full bg-primary text-sm font-bold text-primary-foreground">BT</div>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center justify-between gap-2">
                          <div className="flex items-center gap-1.5 font-semibold">Budi Teknik <BadgeCheck className="size-4 text-primary" aria-label="Terverifikasi" /></div>
                          <Badge>92% cocok</Badge>
                        </div>
                        <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                          <span className="inline-flex items-center gap-1"><Star className="size-3.5 fill-warning text-warning" /> 4,9 (128)</span>
                          <span className="inline-flex items-center gap-1"><MapPin className="size-3.5" /> 2,1 km</span>
                          <span className="inline-flex items-center gap-1"><Clock3 className="size-3.5" /> Tersedia 10:00</span>
                        </div>
                        <div className="mt-3 flex items-end justify-between gap-3 border-t pt-3">
                          <div><p className="text-xs text-muted-foreground">Estimasi kunjungan</p><p className="font-bold">{formatRupiah(200000)}–350.000</p></div>
                          <div className="hidden text-right text-xs text-muted-foreground sm:block"><span className="font-semibold text-foreground">Alasan cocok</span><br />Dekat · Respons cepat</div>
                        </div>
                      </div>
                    </div>
                  </div>
                  {[{ n: "SR", name: "Sejuk Refrigerasi", match: "88%", distance: "3,4 km", price: "250–400 rb" }, { n: "AP", name: "Andi Pratama", match: "84%", distance: "4,0 km", price: "180–325 rb" }].map((provider) => (
                    <div key={provider.name} className="flex items-center gap-3 rounded-lg border p-3.5">
                      <div className="grid size-10 shrink-0 place-items-center rounded-full bg-muted text-xs font-bold">{provider.n}</div>
                      <div className="min-w-0 flex-1"><p className="truncate text-sm font-semibold">{provider.name}</p><p className="text-xs text-muted-foreground">★ 4,8 · {provider.distance}</p></div>
                      <div className="text-right"><p className="text-xs font-semibold text-primary">{provider.match} cocok</p><p className="text-xs text-muted-foreground">{provider.price}</p></div>
                    </div>
                  ))}
                  <p className="px-1 text-xs leading-5 text-muted-foreground"><Sparkles className="mr-1 inline size-3.5 text-primary" /> Rekomendasi AI dapat diubah. Harga akhir dikonfirmasi sebelum pemesanan.</p>
                </CardContent>
              </Card>
              <div className="absolute -bottom-5 -left-4 hidden items-center gap-3 rounded-lg border bg-card p-3 shadow-soft sm:flex">
                <span className="grid size-9 place-items-center rounded-full bg-success/10 text-success"><Check className="size-4" /></span>
                <span><strong className="block text-sm">Identitas terverifikasi</strong><span className="text-xs text-muted-foreground">Status dan masa berlaku jelas</span></span>
              </div>
            </div>
          </div>
        </section>

        <section id="layanan" className="py-20 sm:py-24">
          <div className="container">
            <div className="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
              <div><p className="text-sm font-bold uppercase tracking-[0.18em] text-primary">Jelajahi layanan</p><h2 className="mt-3 text-balance text-3xl font-bold tracking-tight sm:text-4xl">Satu tempat untuk berbagai kebutuhan</h2></div>
              <Link href="/cari" className="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:underline">Lihat semua layanan <ChevronRight className="size-4" /></Link>
            </div>
            <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {categories.map(({ name, description, icon: Icon }) => (
                <Link key={name} href={`/cari?kategori=${encodeURIComponent(name)}`} className="group flex items-center gap-4 rounded-lg border bg-card p-5 shadow-sm transition-[transform,box-shadow,border-color] hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring motion-reduce:transform-none">
                  <span className="grid size-12 shrink-0 place-items-center rounded-lg bg-secondary text-primary transition-colors group-hover:bg-primary group-hover:text-primary-foreground"><Icon className="size-5" /></span>
                  <span className="min-w-0 flex-1"><strong className="block">{name}</strong><span className="mt-1 block text-sm text-muted-foreground">{description}</span></span>
                  <ChevronRight className="size-5 text-muted-foreground transition-transform group-hover:translate-x-1 group-hover:text-primary motion-reduce:transform-none" />
                </Link>
              ))}
            </div>
          </div>
        </section>

        <section id="cara-kerja" className="border-y bg-secondary/45 py-20 sm:py-24">
          <div className="container">
            <div className="mx-auto max-w-2xl text-center"><Badge>Proses yang jelas</Badge><h2 className="mt-4 text-balance text-3xl font-bold tracking-tight sm:text-4xl">Dari masalah ke solusi, dalam tiga langkah</h2><p className="mt-4 text-muted-foreground">Anda tetap memegang keputusan. Teknologi hanya membantu mempercepat dan memperjelas pilihan.</p></div>
            <div className="mt-12 grid gap-5 lg:grid-cols-3">
              {steps.map(({ number, title, description, icon: Icon }) => (
                <Card key={number} className="relative overflow-hidden bg-card/80">
                  <CardHeader><div className="mb-7 flex items-center justify-between"><span className="grid size-11 place-items-center rounded-lg bg-primary text-primary-foreground"><Icon className="size-5" /></span><span className="text-4xl font-black text-primary/10">{number}</span></div><CardTitle>{title}</CardTitle><CardDescription className="text-base">{description}</CardDescription></CardHeader>
                </Card>
              ))}
            </div>
          </div>
        </section>

        <section id="keamanan" className="py-20 sm:py-28">
          <div className="container grid items-center gap-12 lg:grid-cols-2 lg:gap-20">
            <div className="relative rounded-[2rem] bg-[hsl(var(--teal-900))] p-6 text-white shadow-float sm:p-10">
              <div className="absolute right-8 top-8 size-24 rounded-full bg-white/10 blur-2xl" aria-hidden="true" />
              <ShieldCheck className="size-12 text-[hsl(var(--teal-100))]" />
              <h2 className="mt-8 text-3xl font-bold tracking-tight">Kepercayaan bukan sekadar lencana.</h2>
              <p className="mt-4 leading-7 text-white/70">Setiap status punya arti, bukti, dan masa berlaku. Informasi sensitif dibatasi sesuai kebutuhan peran.</p>
              <div className="mt-8 grid gap-3 sm:grid-cols-2">
                {["Verifikasi identitas", "Ulasan dari transaksi", "Riwayat pekerjaan", "Alur sengketa & bukti"].map((item) => <div key={item} className="flex items-center gap-2.5 rounded-lg border border-white/10 bg-white/5 p-3 text-sm"><Check className="size-4 text-[hsl(var(--teal-100))]" /> {item}</div>)}
              </div>
            </div>
            <div>
              <Badge variant="outline">Teknologi yang bertanggung jawab</Badge>
              <h2 className="mt-5 text-balance text-3xl font-bold tracking-tight sm:text-4xl">AI membantu. Anda yang memutuskan.</h2>
              <p className="mt-5 text-lg leading-8 text-muted-foreground">Estimasi selalu menampilkan rentang, asumsi, dan tingkat keyakinan. Jika datanya belum cukup, kami meminta detail atau mengarahkan ke penawaran manual.</p>
              <ul className="mt-8 space-y-5">
                {[
                  [Sparkles, "Rekomendasi dapat dijelaskan", "Ketahui mengapa penyedia muncul dalam hasil Anda."],
                  [Camera, "Foto diproses seperlunya", "Kontrol akses dan retensi mengikuti tujuan penggunaan."],
                  [HeartHandshake, "Keputusan penting ditinjau manusia", "Verifikasi, risiko, dan sengketa memiliki jalur banding."],
                ].map(([Icon, title, description]) => {
                  const FeatureIcon = Icon as typeof Sparkles
                  return <li key={title as string} className="flex gap-4"><span className="grid size-11 shrink-0 place-items-center rounded-lg bg-secondary text-primary"><FeatureIcon className="size-5" /></span><span><strong className="block">{title as string}</strong><span className="mt-1 block text-sm leading-6 text-muted-foreground">{description as string}</span></span></li>
                })}
              </ul>
            </div>
          </div>
        </section>

        <section className="container pb-20 sm:pb-28">
          <div className="relative overflow-hidden rounded-[2rem] bg-primary px-6 py-12 text-primary-foreground shadow-float sm:px-12 lg:flex lg:items-center lg:justify-between lg:gap-10 lg:px-16 lg:py-16">
            <div className="absolute -right-16 -top-16 size-64 rounded-full border-[40px] border-white/10" aria-hidden="true" />
            <div className="relative max-w-2xl"><Badge className="bg-white/15 text-white">Untuk penyedia jasa</Badge><h2 className="mt-5 text-balance text-3xl font-bold tracking-tight sm:text-4xl">Keahlian Anda layak ditemukan pelanggan yang tepat.</h2><p className="mt-4 max-w-xl text-white/75">Kelola layanan, jadwal, pekerjaan, komunikasi, dan pendapatan dari satu ruang kerja.</p></div>
            <Link href="/mitra" className={cn(buttonVariants({ variant: "secondary", size: "lg" }), "relative mt-8 shrink-0 bg-white text-[hsl(var(--teal-900))] hover:bg-white/90 lg:mt-0")}>Daftar sebagai mitra <ArrowRight className="size-4" /></Link>
          </div>
        </section>
      </main>

      <footer className="border-t bg-card py-10">
        <div className="container flex flex-col gap-8 sm:flex-row sm:items-center sm:justify-between">
          <div><p className="font-bold">Lumina Jasa</p><p className="mt-1 text-sm text-muted-foreground">Jasa profesional, lebih mudah dan transparan.</p></div>
          <nav aria-label="Navigasi footer" className="flex flex-wrap gap-x-6 gap-y-3 text-sm text-muted-foreground"><Link href="/#keamanan" className="hover:text-foreground">Keamanan</Link><Link href="/mitra" className="hover:text-foreground">Mitra</Link><Link href="/cari" className="hover:text-foreground">Cari jasa</Link><a href="mailto:halo@luminajasa.id" className="hover:text-foreground">Bantuan</a></nav>
          <p className="text-xs text-muted-foreground">© {new Date().getFullYear()} Lumina Jasa</p>
        </div>
      </footer>
    </div>
  )
}
