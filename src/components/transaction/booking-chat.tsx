"use client"

import { useEffect, useState } from "react"
import { Radio, Send } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

type ChatMessage = { id: string; body: string; senderId: string; createdAt: string }

export function BookingChat({ conversationId, userId, initialMessages }: { conversationId: string; userId: string; initialMessages: ChatMessage[] }) {
  const [messages, setMessages] = useState(initialMessages)
  const [body, setBody] = useState("")
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [realtime, setRealtime] = useState<"connecting" | "live" | "degraded">("connecting")

  useEffect(() => {
    const supabase = createClient(); if (!supabase) { setRealtime("degraded"); return }
    const channel = supabase.channel(`conversation:${conversationId}`).on("postgres_changes", { event: "INSERT", schema: "public", table: "messages", filter: `conversation_id=eq.${conversationId}` }, (payload) => {
      const row = payload.new as { id: string; body: string | null; sender_user_id: string; created_at: string }
      if (!row.body) return
      setMessages((current) => current.some((message) => message.id === row.id) ? current : [...current, { id: row.id, body: row.body!, senderId: row.sender_user_id, createdAt: row.created_at }])
    }).subscribe((status) => setRealtime(status === "SUBSCRIBED" ? "live" : status === "CHANNEL_ERROR" || status === "TIMED_OUT" ? "degraded" : "connecting"))
    return () => { void supabase.removeChannel(channel) }
  }, [conversationId])

  async function send() {
    const text = body.trim(); if (!text) return
    setBusy(true); setError(null)
    const supabase = createClient(); if (!supabase) { setBusy(false); return }
    const { data, error: sendError } = await supabase.rpc("send_moderated_message", { p_conversation_id: conversationId, p_client_id: crypto.randomUUID(), p_body: text })
    if (sendError || !data) setError("Pesan belum terkirim. Jalur manual tetap tersedia.")
    else {
      setMessages((current) => current.some((message) => message.id === data) ? current : [...current, { id: data, body: text, senderId: userId, createdAt: new Date().toISOString() }])
      setBody("")
    }
    setBusy(false)
  }

  return <section aria-labelledby="chat-title"><div className="flex items-center justify-between gap-3"><h2 id="chat-title" className="text-xl font-bold">Percakapan</h2><Badge variant={realtime === "live" ? "success" : "warning"}><Radio className="size-3" />{realtime === "live" ? "Realtime" : realtime === "degraded" ? "Mode tertunda" : "Menghubungkan"}</Badge></div>{realtime === "degraded" && <p role="status" className="mt-2 text-xs text-muted-foreground">Koneksi realtime terganggu. Pesan yang dikirim tetap tersimpan dan akan terlihat setelah halaman dimuat ulang.</p>}<div className="mt-4 max-h-80 space-y-3 overflow-y-auto rounded-lg border bg-muted/30 p-4" aria-live="polite">{messages.length === 0 ? <p className="text-center text-sm text-muted-foreground">Belum ada pesan.</p> : messages.map((message) => <div key={message.id} className={`max-w-[82%] rounded-lg px-3 py-2 text-sm ${message.senderId === userId ? "ml-auto bg-primary text-primary-foreground" : "border bg-card"}`}><p>{message.body}</p><time className="mt-1 block text-[10px] opacity-70">{new Intl.DateTimeFormat("id-ID", { hour: "2-digit", minute: "2-digit" }).format(new Date(message.createdAt))}</time></div>)}</div><div className="mt-3 flex gap-2"><label htmlFor="chat-message" className="sr-only">Tulis pesan</label><Input id="chat-message" value={body} onChange={(event) => setBody(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter" && !event.shiftKey) { event.preventDefault(); void send() } }} placeholder="Tulis pesan…" /><Button size="icon" onClick={send} disabled={busy || !body.trim()} aria-label="Kirim pesan"><Send className="size-4" /></Button></div>{error && <p role="alert" className="mt-2 text-sm text-destructive">{error}</p>}</section>
}
