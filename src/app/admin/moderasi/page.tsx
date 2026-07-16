import type { Metadata } from "next"
import { redirect } from "next/navigation"
import { ModerationQueue, type ModerationItem } from "@/components/admin/moderation-queue"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Moderasi" }
export const dynamic = "force-dynamic"

export default async function ModerationPage() {
  if (!getPublicEnv()) return <main className="container py-16">Supabase belum dikonfigurasi.</main>
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk?next=/admin/moderasi")
  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
  if (!(roles ?? []).some((item) => ["support", "compliance", "admin", "super_admin"].includes(item.role))) redirect("/")
  const { data } = await supabase.from("moderation_cases").select("id,subject_type,labels,confidence,created_at").in("status", ["open", "appealed"]).order("created_at")
  const items: ModerationItem[] = (data ?? []).map((item) => ({ id: item.id, subjectType: item.subject_type, labels: item.labels, confidence: Number(item.confidence), createdAt: item.created_at }))
  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-3xl"><h1 className="text-3xl font-bold">Antrean moderasi</h1><p className="mt-2 text-muted-foreground">Sinyal otomatis hanya menyaring; moderator AAL2 membuat keputusan akhir dengan alasan.</p><div className="mt-8"><ModerationQueue items={items} /></div></div></main>
}
