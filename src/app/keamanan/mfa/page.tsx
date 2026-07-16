import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { ArrowLeft } from "lucide-react"
import { MfaSettings } from "@/components/auth/mfa-settings"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Keamanan akun" }

export default async function MfaPage({ searchParams }: { searchParams: Promise<{ next?: string }> }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk")
  const requestedNext = (await searchParams).next
  const nextPath = requestedNext?.startsWith("/") && !requestedNext.startsWith("//") ? requestedNext : "/"

  return (
    <main id="konten-utama" className="mx-auto flex min-h-screen w-full max-w-xl items-center px-4 py-12 sm:px-6">
      <div className="w-full space-y-5">
        <Link href="/" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" />Kembali</Link>
        <Card className="shadow-float">
          <CardHeader><CardTitle className="text-2xl">Verifikasi dua langkah</CardTitle><CardDescription>Lindungi tindakan sensitif dengan kode sekali pakai dari aplikasi authenticator.</CardDescription></CardHeader>
          <CardContent><MfaSettings nextPath={nextPath} /></CardContent>
        </Card>
      </div>
    </main>
  )
}
