import type { Metadata } from "next"
import { notFound, redirect } from "next/navigation"
import { CustomerTrustActions } from "@/components/trust/customer-trust-actions"
import { Card, CardContent } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Kepercayaan dan Ulasan" }
export const dynamic = "force-dynamic"

export default async function TrustPage({ params }: { params: Promise<{ id: string }> }) {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const id = (await params).id
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect(`/masuk?next=/pesanan/${id}/kepercayaan`)

  const { data: booking } = await supabase.from("bookings").select("id,status,customer_id,total_amount,job:jobs(title)").eq("id", id).maybeSingle()
  if (!booking) notFound()
  const [{ data: dispute }, { count: reviews }] = await Promise.all([
    supabase.from("disputes").select("id").eq("booking_id", id).order("opened_at", { ascending: false }).limit(1).maybeSingle(),
    supabase.from("reviews").select("id", { count: "exact", head: true }).eq("booking_id", id).eq("customer_id", user.id),
  ])
  const isCustomer = booking.customer_id === user.id

  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-2xl"><h1 className="text-3xl font-bold">Kepercayaan dan hasil kerja</h1><p className="mt-2 text-muted-foreground">{(booking.job as unknown as { title: string } | null)?.title}</p><Card className="mt-8"><CardContent className="p-5 sm:p-8"><CustomerTrustActions bookingId={id} totalAmount={booking.total_amount} canDispute={isCustomer && ["in_progress", "provider_completed", "customer_confirmed"].includes(booking.status)} canReview={isCustomer && ["customer_confirmed", "closed", "resolved"].includes(booking.status)} disputeId={dispute?.id ?? null} hasReview={Boolean(reviews)} /></CardContent></Card></div></main>
}
