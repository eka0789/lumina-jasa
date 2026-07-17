import type { Metadata } from "next"
import Link from "next/link"
import { redirect } from "next/navigation"
import { AlertTriangle, BarChart3, ClipboardCheck, Rocket, ShieldCheck } from "lucide-react"
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { getPublicEnv } from "@/lib/env"
import { createClient } from "@/lib/supabase/server"

export const metadata: Metadata = { title: "Dashboard Admin" }
export const dynamic = "force-dynamic"

const ADMIN_MODULES = [
  {
    title: "Antrean Verifikasi",
    description: "Tinjau bukti KYC/KYB dan kelola status profil penyedia.",
    href: "/admin/verifikasi",
    icon: ClipboardCheck,
    color: "text-blue-500",
    bg: "bg-blue-500/10",
  },
  {
    title: "Kontrol Peluncuran",
    description: "Pantau antrean kritis dan kelola fitur platform.",
    href: "/admin/peluncuran",
    icon: Rocket,
    color: "text-indigo-500",
    bg: "bg-indigo-500/10",
  },
  {
    title: "Operasi Kepercayaan",
    description: "Kelola asuransi, sengketa, dan tingkat kepercayaan platform.",
    href: "/admin/kepercayaan",
    icon: ShieldCheck,
    color: "text-emerald-500",
    bg: "bg-emerald-500/10",
  },
  {
    title: "Moderasi Konten",
    description: "Tinjau dan tindak lanjuti laporan serta ulasan bermasalah.",
    href: "/admin/moderasi",
    icon: AlertTriangle,
    color: "text-amber-500",
    bg: "bg-amber-500/10",
  },
  {
    title: "Metrik & Skala",
    description: "Pantau kinerja sistem dan metrik pertumbuhan keseluruhan.",
    href: "/admin/skala",
    icon: BarChart3,
    color: "text-purple-500",
    bg: "bg-purple-500/10",
  },
]

export default async function AdminDashboardPage() {
  if (!getPublicEnv()) {
    return (
      <main className="container py-16">
        <Card className="mx-auto max-w-xl">
          <CardHeader>
            <CardTitle>Supabase belum dikonfigurasi</CardTitle>
            <CardDescription>Akses ke dashboard admin memerlukan environment Supabase.</CardDescription>
          </CardHeader>
        </Card>
      </main>
    )
  }

  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect("/masuk?next=/admin")

  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
  const roleNames = (roles ?? []).map((item) => item.role)
  
  if (!roleNames.some((role) => ["support", "admin", "compliance", "super_admin"].includes(role))) {
    redirect("/")
  }

  return (
    <main id="konten-utama" className="container py-10 sm:py-14">
      <div className="mx-auto max-w-5xl">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Dashboard Admin</h1>
        <p className="mt-3 text-lg text-muted-foreground">
          Pilih modul di bawah ini untuk mengelola operasional platform Lumina Jasa.
        </p>
        
        <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {ADMIN_MODULES.map((modul) => (
            <Link key={modul.href} href={modul.href} className="group outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 rounded-xl">
              <Card className="h-full transition-colors hover:bg-muted/50 group-focus-visible:bg-muted/50">
                <CardHeader>
                  <div className={`mb-4 inline-flex size-12 items-center justify-center rounded-lg ${modul.bg}`}>
                    <modul.icon className={`size-6 ${modul.color}`} aria-hidden="true" />
                  </div>
                  <CardTitle className="text-xl">{modul.title}</CardTitle>
                  <CardDescription className="mt-2 text-sm leading-relaxed">
                    {modul.description}
                  </CardDescription>
                </CardHeader>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </main>
  )
}
