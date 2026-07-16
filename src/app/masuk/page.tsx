import type { Metadata } from "next"
import Link from "next/link"
import { ArrowLeft, BadgeCheck, LockKeyhole, ShieldCheck } from "lucide-react"
import { Logo } from "@/components/logo"
import { SignInForm } from "@/components/auth/sign-in-form"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

export const metadata: Metadata = { title: "Masuk" }

export default function SignInPage() {
  return (
    <main id="konten-utama" className="grid min-h-screen lg:grid-cols-[1fr_.9fr]">
      <section className="hidden bg-[hsl(var(--teal-900))] p-12 text-white lg:flex lg:flex-col lg:justify-between">
        <Logo className="text-white [&_span:last-child]:text-white" />
        <div className="max-w-lg">
          <p className="text-sm font-bold uppercase tracking-[0.2em] text-[hsl(var(--teal-100))]">Ruang kerja tepercaya</p>
          <h1 className="mt-5 text-4xl font-bold leading-tight tracking-tight">Satu akun untuk mencari jasa, mengelola bisnis, atau melayani pelanggan.</h1>
          <ul className="mt-9 space-y-4 text-sm text-white/75">
            <li className="flex items-center gap-3"><BadgeCheck className="size-5 text-[hsl(var(--teal-100))]" /> Peran dan akses dapat berbeda di setiap organisasi</li>
            <li className="flex items-center gap-3"><ShieldCheck className="size-5 text-[hsl(var(--teal-100))]" /> Aktivitas penting tercatat dan dapat ditinjau</li>
            <li className="flex items-center gap-3"><LockKeyhole className="size-5 text-[hsl(var(--teal-100))]" /> Data sensitif dibatasi sesuai kebutuhan</li>
          </ul>
        </div>
        <p className="text-xs text-white/50">Gunakan hanya perangkat yang Anda percaya.</p>
      </section>
      <section className="flex items-center justify-center px-4 py-12 sm:px-8">
        <div className="w-full max-w-md">
          <div className="mb-8 flex items-center justify-between lg:hidden"><Logo /><Link href="/" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><ArrowLeft className="size-4" /> Kembali</Link></div>
          <Card className="shadow-float">
            <CardHeader><CardTitle className="text-2xl">Selamat datang kembali</CardTitle><CardDescription>Masuk untuk melanjutkan aktivitas Lumina Jasa.</CardDescription></CardHeader>
            <CardContent><SignInForm /><p className="mt-6 text-center text-sm text-muted-foreground">Belum punya akun? <Link href="/mitra" className="font-semibold text-primary hover:underline">Mulai di sini</Link></p></CardContent>
          </Card>
          <p className="mt-6 text-center text-xs leading-5 text-muted-foreground">Dengan melanjutkan, Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi Lumina Jasa.</p>
        </div>
      </section>
    </main>
  )
}
