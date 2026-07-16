import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { ArrowLeft, ClipboardCheck, ShieldAlert } from "lucide-react"
import { VerificationQueue, type VerificationQueueItem } from "@/components/admin/verification-queue"
import { Badge } from "@/components/ui/badge"
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Antrean Verifikasi" }
export const dynamic = "force-dynamic"

type RawCase = {
  id: string
  kind: string
  submitted_at: string
  provider: { display_name: string; slug: string; service_area_labels: string[]; service_radius_km: number | null } | null
  documents: Array<{ document_type: string; file: { id: string; bucket: string; object_path: string; scan_status: string } | null }>
}

export default async function VerificationAdminPage() {
  if (!getPublicEnv()) return <main className="container py-16"><Card className="mx-auto max-w-xl"><CardHeader><CardTitle>Supabase belum dikonfigurasi</CardTitle><CardDescription>Antrean admin memerlukan environment Supabase.</CardDescription></CardHeader></Card></main>
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk?next=/admin/verifikasi")
  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
  if (!(roles ?? []).some(({ role }) => ["admin", "compliance", "super_admin"].includes(role))) redirect("/")
  const { data, error } = await supabase.from("verification_cases")
    .select("id, kind, submitted_at, provider:providers(display_name, slug, service_area_labels, service_radius_km), documents:compliance_documents(document_type, file:files(id, bucket, object_path, scan_status))")
    .in("status", ["pending", "processing", "manual_review"]).not("provider_id", "is", null).order("submitted_at")
  if (error) throw new Error(`Antrean verifikasi tidak dapat dimuat: ${error.message}`)

  const items: VerificationQueueItem[] = await Promise.all(((data ?? []) as unknown as RawCase[]).map(async (item) => {
    const document = item.documents[0]
    const signed = document?.file ? await supabase.storage.from(document.file.bucket).createSignedUrl(document.file.object_path, 600) : null
    return {
      id: item.id, kind: item.kind, submittedAt: item.submitted_at,
      provider: item.provider ? { name: item.provider.display_name, slug: item.provider.slug, areas: item.provider.service_area_labels, radiusKm: item.provider.service_radius_km } : null,
      document: document?.file && signed?.data?.signedUrl ? { fileId: document.file.id, url: signed.data.signedUrl, type: document.document_type, scanStatus: document.file.scan_status } : null,
    }
  }))

  return <main id="konten-utama" className="container py-10 sm:py-14"><div className="mx-auto max-w-4xl"><Link href="/" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />Beranda</Link><div className="mt-8 flex flex-col justify-between gap-5 sm:flex-row sm:items-end"><div><Badge><ClipboardCheck className="size-3.5" />Operasi kepercayaan</Badge><h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">Antrean verifikasi penyedia</h1><p className="mt-3 max-w-2xl text-muted-foreground">Tinjau bukti KYC/KYB, catat alasan, lalu aktifkan atau tolak profil.</p></div><div className="inline-flex items-center gap-2 rounded-lg border border-warning/25 bg-warning/10 p-3 text-xs"><ShieldAlert className="size-4" />AAL2 wajib untuk keputusan</div></div><div className="mt-8"><VerificationQueue initialItems={items} /></div></div></main>
}
