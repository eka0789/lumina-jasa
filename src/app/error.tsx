"use client"

import { useEffect } from "react"
import Link from "next/link"
import { AlertTriangle } from "lucide-react"

export default function GlobalError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <main className="grid min-h-[calc(100vh-4.5rem)] place-items-center px-6 py-24 text-foreground">
      <div className="text-center max-w-md">
        <AlertTriangle className="mx-auto mb-6 size-12 text-destructive" aria-hidden="true" />
        <h1 className="text-2xl font-bold">Terjadi kesalahan</h1>
        <p className="mt-3 text-muted-foreground">
          Maaf, ada sesuatu yang tidak beres. Silakan coba lagi atau kembali ke beranda.
        </p>
        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <button
            onClick={reset}
            className="rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground hover:bg-primary/90"
          >
            Coba lagi
          </button>
          <Link
            href="/"
            className="rounded-md border border-border px-5 py-2.5 text-sm font-semibold hover:bg-accent"
          >
            Kembali ke beranda
          </Link>
        </div>
        {error.digest && (
          <p className="mt-6 text-xs text-muted-foreground">ID error: {error.digest}</p>
        )}
      </div>
    </main>
  )
}
