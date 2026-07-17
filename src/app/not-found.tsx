import type { Metadata } from "next"
import Link from "next/link"
import { FileQuestion } from "lucide-react"
import { SiteHeader } from "@/components/site-header"

export const metadata: Metadata = {
  title: "Halaman Tidak Ditemukan",
  description: "Halaman yang Anda cari tidak dapat ditemukan.",
}

export default function NotFound() {
  return (
    <>
      <SiteHeader />
      <main id="konten-utama" className="grid min-h-[calc(100vh-4.5rem)] place-items-center px-6 py-24">
        <div className="text-center max-w-md">
          <FileQuestion className="mx-auto mb-6 size-12 text-muted-foreground" aria-hidden="true" />
          <h1 className="text-3xl font-bold tracking-tight">404 — Halaman tidak ditemukan</h1>
          <p className="mt-4 text-muted-foreground">
            Halaman yang Anda cari mungkin sudah dipindahkan, dihapus, atau URL-nya salah ketik.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
            <Link
              href="/"
              className="rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground hover:bg-primary/90"
            >
              Kembali ke beranda
            </Link>
            <Link
              href="/cari"
              className="rounded-md border border-border px-5 py-2.5 text-sm font-semibold hover:bg-accent"
            >
              Cari jasa
            </Link>
          </div>
        </div>
      </main>
    </>
  )
}
