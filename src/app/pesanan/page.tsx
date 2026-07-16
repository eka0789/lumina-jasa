import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { CalendarDays, ChevronRight } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"
import { formatRupiah } from "@/lib/utils"

export const metadata: Metadata = { title: "Pesanan Saya" }
export const dynamic = "force-dynamic"
type RawBooking = { id: string; status: string; scheduled_start: string; total_amount: number; job: { title: string } | null; provider: { display_name: string } | null }

export default async function CustomerBookingsPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect("/masuk?next=/pesanan")
  const { data, error } = await supabase.from("bookings").select("id,status,scheduled_start,total_amount,job:jobs(title),provider:providers(display_name)").eq("customer_id", user.id).order("scheduled_start", { ascending: false }); if (error) throw new Error(error.message)
  const bookings = (data ?? []) as unknown as RawBooking[]
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-4xl"><div className="flex items-end justify-between gap-4"><div><h1 className="text-3xl font-bold">Pesanan saya</h1><p className="mt-2 text-muted-foreground">Pantau jadwal, pembayaran, pekerjaan, dan percakapan.</p></div><Link href="/pesan" className="text-sm font-semibold text-primary hover:underline">Buat permintaan</Link></div><div className="mt-8 space-y-4">{bookings.length === 0 ? <Card><CardContent className="p-8 text-center text-muted-foreground">Belum ada pesanan.</CardContent></Card> : bookings.map((booking) => <Link key={booking.id} href={booking.status === "awaiting_payment" ? `/pesanan/${booking.id}/bayar` : `/pesanan/${booking.id}`} className="flex items-center gap-4 rounded-lg border bg-card p-5 shadow-sm transition-colors hover:border-primary/30"><CalendarDays className="size-5 text-primary" /><span className="min-w-0 flex-1"><strong className="block truncate">{booking.job?.title}</strong><span className="mt-1 block text-sm text-muted-foreground">{booking.provider?.display_name} · {new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(booking.scheduled_start))} · {formatRupiah(booking.total_amount)}</span></span><Badge>{booking.status.replaceAll("_", " ")}</Badge><ChevronRight className="size-5 text-muted-foreground" /></Link>)}</div></div></main>
}
