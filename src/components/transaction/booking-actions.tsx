"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { AlertCircle, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { getNextBookingAction } from "@/lib/booking-workflow"
import { createClient } from "@/lib/supabase/client"

export function BookingActions({ bookingId, status, isProvider }: { bookingId: string; status: string; isProvider: boolean }) {
  const router = useRouter()
  const action = getNextBookingAction(status, isProvider)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  if (!action) return null
  const { status: nextStatus, label } = action

  async function transition() {
    setBusy(true); setError(null)
    const supabase = createClient()
    if (!supabase) { setBusy(false); return }
    const { error: rpcError } = await supabase.rpc("transition_booking", { p_booking_id: bookingId, p_to_status: nextStatus, p_note: "", p_idempotency_key: crypto.randomUUID() })
    if (rpcError) setError("Status tidak dapat diubah. Muat ulang untuk melihat status terbaru.")
    else router.refresh()
    setBusy(false)
  }

  return <div>{error && <p role="alert" className="mb-3 flex gap-2 text-sm text-destructive"><AlertCircle className="size-4" />{error}</p>}<Button className="w-full" onClick={transition} disabled={busy}>{busy && <LoaderCircle className="size-4 animate-spin" />}{label}</Button></div>
}
