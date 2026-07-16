"use client"

import { useEffect, useState } from "react"
import { LoaderCircle, LocateFixed, Radio } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { createClient } from "@/lib/supabase/client"

type Point = { latitude: number; longitude: number; capturedAt: string; accuracy: number | null }

function parsePoint(row: { location?: unknown; captured_at?: string; accuracy_meters?: number | null }): Point | null {
  const location = row.location as { coordinates?: [number, number] } | null
  if (!location?.coordinates || !row.captured_at) return null
  return { longitude: location.coordinates[0], latitude: location.coordinates[1], capturedAt: row.captured_at, accuracy: row.accuracy_meters ?? null }
}

export function BookingTracking({ bookingId, isProvider, status, initialPoint }: { bookingId: string; isProvider: boolean; status: string; initialPoint: Point | null }) {
  const [point, setPoint] = useState(initialPoint)
  const [connection, setConnection] = useState<"connecting" | "live" | "degraded">("connecting")
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const supabase = createClient(); if (!supabase) { setConnection("degraded"); return }
    const channel = supabase.channel(`tracking:${bookingId}`).on("postgres_changes", { event: "INSERT", schema: "public", table: "tracking_points", filter: `booking_id=eq.${bookingId}` }, (payload) => {
      const next = parsePoint(payload.new); if (next) setPoint(next)
    }).subscribe((value) => setConnection(value === "SUBSCRIBED" ? "live" : value === "CHANNEL_ERROR" || value === "TIMED_OUT" ? "degraded" : "connecting"))
    return () => { void supabase.removeChannel(channel) }
  }, [bookingId])

  function shareLocation() {
    if (!navigator.geolocation) return setError("Perangkat ini tidak menyediakan lokasi.")
    setBusy(true); setError(null)
    navigator.geolocation.getCurrentPosition(async (position) => {
      const supabase = createClient(); if (!supabase) { setBusy(false); return }
      const { error: rpcError } = await supabase.rpc("publish_tracking_point", { p_booking_id: bookingId, p_latitude: position.coords.latitude, p_longitude: position.coords.longitude, p_accuracy: position.coords.accuracy, p_captured_at: new Date(position.timestamp).toISOString() })
      if (rpcError) setError("Lokasi tidak dapat dibagikan pada status ini.")
      else setPoint({ latitude: position.coords.latitude, longitude: position.coords.longitude, accuracy: position.coords.accuracy, capturedAt: new Date(position.timestamp).toISOString() })
      setBusy(false)
    }, () => { setError("Izin lokasi ditolak atau posisi tidak tersedia."); setBusy(false) }, { enableHighAccuracy: true, timeout: 10000, maximumAge: 30000 })
  }

  const shareable = isProvider && ["en_route", "in_progress"].includes(status)
  return <section aria-labelledby="tracking-title" className="rounded-lg border bg-card p-5"><div className="flex flex-wrap items-center justify-between gap-3"><h2 id="tracking-title" className="flex items-center gap-2 text-xl font-bold"><LocateFixed className="size-5 text-primary" />Pelacakan kedatangan</h2><Badge variant={connection === "live" ? "success" : "warning"}><Radio className="size-3" />{connection === "live" ? "Realtime" : "Fallback aktif"}</Badge></div>{point ? <div className="mt-4 text-sm"><p className="font-semibold">Posisi terakhir: {point.latitude.toFixed(4)}, {point.longitude.toFixed(4)}</p><p className="mt-1 text-muted-foreground">{new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(new Date(point.capturedAt))}{point.accuracy ? ` · akurasi ±${Math.round(point.accuracy)} m` : ""}</p></div> : <p className="mt-4 text-sm text-muted-foreground">Belum ada lokasi yang dibagikan. Pesanan tetap dapat berjalan tanpa pelacakan.</p>}{shareable && <Button className="mt-4" variant="outline" size="sm" onClick={shareLocation} disabled={busy}>{busy && <LoaderCircle className="size-4 animate-spin" />}Bagikan posisi sekarang</Button>}{connection === "degraded" && <p className="mt-3 text-xs text-muted-foreground">Pembaruan langsung terganggu; muat ulang halaman untuk mengambil posisi terbaru.</p>}{error && <p role="alert" className="mt-3 text-sm text-destructive">{error}</p>}</section>
}
