"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { AlertCircle, CheckCircle2, LoaderCircle, ShieldAlert, Star } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

type Props = {
  bookingId: string
  totalAmount: number
  canDispute: boolean
  canReview: boolean
  disputeId: string | null
  hasReview: boolean
}

export function CustomerTrustActions({ bookingId, totalAmount, canDispute, canReview, disputeId, hasReview }: Props) {
  const router = useRouter()
  const [reasonCode, setReasonCode] = useState("service_quality")
  const [description, setDescription] = useState("")
  const [amount, setAmount] = useState(totalAmount)
  const [evidenceNote, setEvidenceNote] = useState("")
  const [rating, setRating] = useState(5)
  const [review, setReview] = useState("")
  const [busy, setBusy] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  async function runRpc(name: string, args: Record<string, unknown>, key: string, success: string) {
    setBusy(key)
    setError(null)
    setMessage(null)
    const supabase = createClient()
    if (!supabase) {
      setBusy(null)
      return
    }
    const { error: rpcError } = await supabase.rpc(name, args)
    if (rpcError) setError("Permintaan tidak dapat diproses untuk status atau data ini.")
    else {
      setMessage(success)
      router.refresh()
    }
    setBusy(null)
  }

  function openDispute() {
    if (description.trim().length < 20) return setError("Jelaskan masalah dalam minimal 20 karakter.")
    return runRpc(
      "open_booking_dispute",
      { p_booking_id: bookingId, p_reason_code: reasonCode, p_description: description, p_amount: amount, p_correlation_id: crypto.randomUUID() },
      "dispute",
      "Sengketa dibuka dan pelepasan pembayaran dibekukan.",
    )
  }

  function addEvidence() {
    if (!disputeId || evidenceNote.trim().length < 10) return setError("Catatan bukti minimal 10 karakter.")
    return runRpc(
      "add_dispute_evidence_note",
      { p_dispute_id: disputeId, p_note: evidenceNote, p_correlation_id: crypto.randomUUID() },
      "evidence",
      "Catatan bukti berhasil ditambahkan ke jejak audit.",
    )
  }

  function submitReview() {
    return runRpc(
      "submit_verified_review",
      { p_booking_id: bookingId, p_rating: rating, p_title: "Ulasan pekerjaan", p_body: review },
      "review",
      "Ulasan terverifikasi berhasil diterbitkan.",
    )
  }

  return (
    <div className="space-y-8">
      {error && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="size-4" />{error}</div>}
      {message && <div role="status" className="flex gap-2 rounded-md border border-success/20 bg-success/5 p-3 text-sm text-success"><CheckCircle2 className="size-4" />{message}</div>}

      <section aria-labelledby="dispute-title">
        <h2 id="dispute-title" className="flex items-center gap-2 text-xl font-bold"><ShieldAlert className="size-5 text-primary" />Sengketa</h2>
        {disputeId ? (
          <div className="mt-4 space-y-4">
            <p className="text-sm text-muted-foreground">Sengketa sudah tercatat. Tambahkan kronologi, hasil percakapan, atau fakta pendukung sebagai catatan bukti.</p>
            <label className="block text-sm font-semibold">Catatan bukti<textarea className="mt-2 w-full rounded-md border bg-background px-3 py-2 font-normal" rows={4} value={evidenceNote} onChange={(event) => setEvidenceNote(event.target.value)} /></label>
            <Button variant="outline" onClick={addEvidence} disabled={busy === "evidence"}>{busy === "evidence" && <LoaderCircle className="size-4 animate-spin" />}Tambahkan bukti</Button>
          </div>
        ) : canDispute ? (
          <div className="mt-4 space-y-4">
            <label className="block text-sm font-semibold">Kategori<select className="mt-2 min-h-11 w-full rounded-md border bg-background px-3" value={reasonCode} onChange={(event) => setReasonCode(event.target.value)}><option value="service_quality">Kualitas layanan</option><option value="not_completed">Pekerjaan belum selesai</option><option value="amount">Perbedaan nominal</option><option value="safety">Keamanan</option></select></label>
            <label className="block text-sm font-semibold">Penjelasan<textarea className="mt-2 w-full rounded-md border bg-background px-3 py-2 font-normal" rows={4} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
            <label className="block text-sm font-semibold">Nominal disengketakan<Input className="mt-2" type="number" min={0} max={totalAmount} value={amount} onChange={(event) => setAmount(Number(event.target.value))} /></label>
            <Button variant="destructive" onClick={openDispute} disabled={busy === "dispute"}>{busy === "dispute" && <LoaderCircle className="size-4 animate-spin" />}Buka sengketa</Button>
          </div>
        ) : <p className="mt-3 text-sm text-muted-foreground">Sengketa belum tersedia pada status pesanan ini.</p>}
      </section>

      <section aria-labelledby="review-title" className="border-t pt-8">
        <h2 id="review-title" className="flex items-center gap-2 text-xl font-bold"><Star className="size-5 text-warning" />Ulasan terverifikasi</h2>
        {hasReview ? <p className="mt-3 text-sm text-muted-foreground">Ulasan sudah dikirim.</p> : canReview ? (
          <div className="mt-4 space-y-4">
            <fieldset><legend className="text-sm font-semibold">Rating</legend><div className="mt-2 flex gap-2">{[1, 2, 3, 4, 5].map((value) => <button key={value} type="button" onClick={() => setRating(value)} className={`grid size-11 place-items-center rounded-md border ${value <= rating ? "bg-warning/15 text-warning-foreground" : "bg-background"}`} aria-label={`${value} bintang`}><Star className={`size-5 ${value <= rating ? "fill-warning text-warning" : ""}`} /></button>)}</div></fieldset>
            <label className="block text-sm font-semibold">Pengalaman Anda<textarea className="mt-2 w-full rounded-md border bg-background px-3 py-2 font-normal" rows={4} value={review} onChange={(event) => setReview(event.target.value)} /></label>
            <Button onClick={submitReview} disabled={busy === "review"}>{busy === "review" && <LoaderCircle className="size-4 animate-spin" />}Kirim ulasan</Button>
          </div>
        ) : <p className="mt-3 text-sm text-muted-foreground">Ulasan tersedia setelah hasil pekerjaan dikonfirmasi.</p>}
      </section>
    </div>
  )
}
