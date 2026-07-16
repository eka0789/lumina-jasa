import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { CalendarDays, ChevronRight } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"
import { formatRupiah } from "@/lib/utils"

export const metadata: Metadata = { title: "Pesanan Mitra" }
export const dynamic = "force-dynamic"
type RawBooking = { id: string; status: string; scheduled_start: string; total_amount: number; job: { title: string } | null }

export default async function ProviderBookingsPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect("/masuk?next=/mitra/pesanan")
  const { data: memberships } = await supabase.from("provider_members").select("provider_id").eq("user_id", user.id).eq("status", "active")
  const providerIds = (memberships ?? []).map((item) => item.provider_id); if (providerIds.length === 0) redirect("/mitra/daftar")
  const { data, error } = await supabase.from("bookings").select("id,status,scheduled_start,total_amount,job:jobs(title)").in("provider_id", providerIds).order("scheduled_start", { ascending: false }); if (error) throw new Error(error.message)
  const bookings = (data ?? []) as unknown as RawBooking[]
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-4xl"><div className="flex items-end justify-between gap-4"><div><h1 className="text-3xl font-bold">Pesanan mitra</h1><p className="mt-2 text-muted-foreground">Kelola pekerjaan terjadwal dan lanjutkan status secara berurutan.</p></div><Link href="/mitra/permintaan" className="text-sm font-semibold text-primary hover:underline">Permintaan baru</Link></div><div className="mt-8 space-y-4">{bookings.length === 0 ? <Card><CardContent className="p-8 text-center text-muted-foreground">Belum ada pesanan terjadwal.</CardContent></Card> : bookings.map((booking) => <Link key={booking.id} href={`/pesanan/${booking.id}`} className="flex items-center gap-4 rounded-lg border bg-card p-5 shadow-sm transition-colors hover:border-primary/30"><CalendarDays className="size-5 text-primary" /><span className="min-w-0 flex-1"><strong className="block truncate">{booking.job?.title}</strong><span className="mt-1 block text-sm text-muted-foreground">{new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(booking.scheduled_start))} · {formatRupiah(booking.total_amount)}</span></span><Badge>{booking.status.replaceAll("_", " ")}</Badge><ChevronRight className="size-5 text-muted-foreground" /></Link>)}</div></div></main>
}
