import type { Metadata } from "next"
import "@/app/globals.css"
import { ThemeProvider } from "@/components/theme-provider"

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000"),
  title: { default: "Lumina Jasa — Temukan Ahli, Selesaikan Masalah", template: "%s | Lumina Jasa" },
  description: "Marketplace jasa tepercaya yang membantu Anda menemukan penyedia terverifikasi dengan pencocokan dan estimasi berbantuan AI.",
  applicationName: "Lumina Jasa",
  openGraph: {
    title: "Lumina Jasa",
    description: "Jasa profesional, lebih mudah ditemukan dan lebih aman dikerjakan.",
    locale: "id_ID",
    type: "website",
  },
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body>
        <ThemeProvider>
          <a href="#konten-utama" className="fixed left-4 top-4 z-[100] -translate-y-24 rounded-md bg-primary px-4 py-3 font-semibold text-primary-foreground shadow-lg transition-transform focus:translate-y-0">
            Lewati ke konten utama
          </a>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
