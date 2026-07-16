import type { Metadata } from "next"
import Link from "next/link"
import { notFound, redirect } from "next/navigation"
import { CalendarDays, CheckCircle2, FileText, MapPin, ReceiptText } from "lucide-react"
import { BookingActions } from "@/components/transaction/booking-actions"
import { BookingChat } from "@/components/transaction/booking-chat"
import { BookingTracking } from "@/components/transaction/booking-tracking"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"
import { formatRupiah } from "@/lib/utils"

export const metadata: Metadata = { title: "Detail Pesanan" }
export const dynamic = "force-dynamic"

type RawBooking = {
  id: string; status: string; customer_id: string; provider_id: string
  scheduled_start: string; scheduled_end: string; subtotal: number; platform_fee: number; total_amount: number
  job: { title: string; description: string } | null
  provider: { display_name: string } | null
  job_status_events: Array<{ id: number; from_status: string | null; to_status: string; created_at: string; note: string | null }>
}

const labels: Record<string, string> = { awaiting_payment: "Menunggu pembayaran", confirmed: "Terkonfirmasi", accepted: "Diterima penyedia", en_route: "Penyedia menuju lokasi", in_progress: "Sedang dikerjakan", provider_completed: "Selesai oleh penyedia", customer_confirmed: "Hasil dikonfirmasi", closed: "Ditutup", cancelled: "Dibatalkan" }

export default async function BookingPage({ params }: { params: Promise<{ id: string }> }) {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const id = (await params).id
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect(`/masuk?next=/pesanan/${id}`)
  const { data, error } = await supabase.from("bookings").select("id,status,customer_id,provider_id,scheduled_start,scheduled_end,subtotal,platform_fee,total_amount,job:jobs(title,description),provider:providers(display_name),job_status_events(id,from_status,to_status,created_at,note)").eq("id", id).maybeSingle()
  if (error || !data) notFound()
  const booking = data as unknown as RawBooking
  const [{ data: membership }, { data: invoice }, { data: conversation }, { data: latestPoint }] = await Promise.all([
    supabase.from("provider_members").select("provider_id").eq("provider_id", booking.provider_id).eq("user_id", user.id).eq("status", "active").maybeSingle(),
    supabase.from("invoices").select("invoice_number,status,issued_at").eq("booking_id", id).maybeSingle(),
    supabase.from("conversations").select("id").eq("booking_id", id).maybeSingle(),
    supabase.from("tracking_points").select("location,accuracy_meters,captured_at").eq("booking_id", id).order("captured_at", { ascending: false }).limit(1).maybeSingle(),
  ])
  const { data: rawMessages } = conversation ? await supabase.from("messages").select("id,body,sender_user_id,created_at").eq("conversation_id", conversation.id).is("deleted_at", null).order("created_at") : { data: [] }
  const messages = (rawMessages ?? []).filter((message) => message.body).map((message) => ({ id: message.id, body: message.body!, senderId: message.sender_user_id, createdAt: message.created_at }))
  const isProvider = Boolean(membership)
  const geo = latestPoint?.location as unknown as { coordinates?: [number, number] } | null
  const initialPoint = geo?.coordinates && latestPoint ? { longitude: geo.coordinates[0], latitude: geo.coordinates[1], accuracy: latestPoint.accuracy_meters, capturedAt: latestPoint.captured_at } : null

  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-5xl">
    <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end"><div><Badge variant="success"><CheckCircle2 className="size-3.5" />{labels[booking.status] ?? booking.status}</Badge><h1 className="mt-4 text-3xl font-bold">{booking.job?.title}</h1><p className="mt-2 text-muted-foreground">{booking.provider?.display_name}</p><Link href={`/pesanan/${booking.id}/kepercayaan`} className="mt-3 inline-block text-sm font-semibold text-primary hover:underline">Sengketa dan ulasan</Link></div><div className="w-full sm:w-56"><BookingActions bookingId={booking.id} status={booking.status} isProvider={isProvider} /></div></div>
    <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_320px]"><div className="space-y-8">
      <Card><CardContent className="p-5"><p className="leading-7 text-muted-foreground">{booking.job?.description}</p><div className="mt-5 grid gap-3 border-t pt-5 sm:grid-cols-2"><span className="flex gap-2 text-sm"><CalendarDays className="size-4 text-primary" />{new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(booking.scheduled_start))}</span><span className="flex gap-2 text-sm"><MapPin className="size-4 text-primary" />Alamat dibagikan kepada peserta booking</span></div></CardContent></Card>
      <BookingTracking bookingId={booking.id} isProvider={isProvider} status={booking.status} initialPoint={initialPoint} />
      <section><h2 className="text-xl font-bold">Timeline</h2><ol className="mt-4 space-y-0">{booking.job_status_events.sort((a, b) => a.created_at.localeCompare(b.created_at)).map((event, index) => <li key={event.id} className="relative flex gap-4 pb-6"><span className="z-10 mt-1 size-3 shrink-0 rounded-full bg-primary ring-4 ring-background" />{index < booking.job_status_events.length - 1 && <span className="absolute left-[5px] top-4 h-full w-px bg-border" />}<div><p className="font-semibold">{labels[event.to_status] ?? event.to_status}</p><time className="text-xs text-muted-foreground">{new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(event.created_at))}</time>{event.note && <p className="mt-1 text-sm">{event.note}</p>}</div></li>)}</ol></section>
      {conversation && <BookingChat conversationId={conversation.id} userId={user.id} initialMessages={messages} />}
    </div><aside><Card className="sticky top-24"><CardHeader><CardTitle>Ringkasan biaya</CardTitle></CardHeader><CardContent className="space-y-3 text-sm"><div className="flex justify-between"><span>Layanan</span><span>{formatRupiah(booking.subtotal)}</span></div><div className="flex justify-between"><span>Biaya platform</span><span>{formatRupiah(booking.platform_fee)}</span></div><div className="flex justify-between border-t pt-3 font-bold"><span>Total</span><span>{formatRupiah(booking.total_amount)}</span></div>{invoice && <div className="mt-4 rounded-lg bg-muted p-3"><p className="flex items-center gap-2 font-semibold"><ReceiptText className="size-4" />{invoice.invoice_number}</p><p className="mt-1 text-xs text-muted-foreground">Invoice {invoice.status}</p></div>}<p className="flex gap-2 pt-3 text-xs leading-5 text-muted-foreground"><FileText className="size-4 shrink-0" />Nominal berasal dari snapshot quote dan tidak dihitung ulang oleh browser.</p></CardContent></Card></aside></div>
  </div></main>
}
