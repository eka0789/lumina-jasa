import Link from "next/link"
import { Logo } from "@/components/logo"

export function SiteFooter() {
  return (
    <footer className="border-t bg-muted/40 py-12">
      <div className="container grid grid-cols-1 gap-8 sm:grid-cols-2 md:grid-cols-4">
        <div className="flex flex-col gap-4">
          <Logo />
          <p className="text-sm text-muted-foreground">
            Marketplace jasa profesional tepercaya. Selesaikan masalah Anda dengan ahli yang terverifikasi.
          </p>
        </div>
        <div className="flex flex-col gap-4">
          <h3 className="font-semibold">Layanan</h3>
          <Link href="/cari" className="text-sm text-muted-foreground hover:text-foreground">Cari Jasa</Link>
          <Link href="/pesan" className="text-sm text-muted-foreground hover:text-foreground">Buat Permintaan</Link>
          <Link href="/mitra" className="text-sm text-muted-foreground hover:text-foreground">Jadi Mitra</Link>
        </div>
        <div className="flex flex-col gap-4">
          <h3 className="font-semibold">Perusahaan</h3>
          <Link href="/tentang" className="text-sm text-muted-foreground hover:text-foreground">Tentang Kami</Link>
          <Link href="/kontak" className="text-sm text-muted-foreground hover:text-foreground">Hubungi Kami</Link>
          <Link href="/karir" className="text-sm text-muted-foreground hover:text-foreground">Karir</Link>
        </div>
        <div className="flex flex-col gap-4">
          <h3 className="font-semibold">Legal</h3>
          <Link href="/syarat" className="text-sm text-muted-foreground hover:text-foreground">Syarat & Ketentuan</Link>
          <Link href="/privasi" className="text-sm text-muted-foreground hover:text-foreground">Kebijakan Privasi</Link>
        </div>
      </div>
      <div className="container mt-12 flex flex-col items-center justify-between gap-4 border-t pt-8 text-sm text-muted-foreground sm:flex-row">
        <p>© {new Date().getFullYear()} Lumina Jasa. Hak cipta dilindungi.</p>
      </div>
    </footer>
  )
}
