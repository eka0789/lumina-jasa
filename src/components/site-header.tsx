import Link from "next/link"
import { Menu, LogOut } from "lucide-react"
import { Logo } from "@/components/logo"
import { ThemeToggle } from "@/components/theme-toggle"
import { buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { createClient } from "@/lib/supabase/server"

const links = [
  { href: "/#layanan", label: "Layanan" },
  { href: "/#cara-kerja", label: "Cara kerja" },
  { href: "/#keamanan", label: "Keamanan" },
  { href: "/pesan", label: "Buat permintaan" },
  { href: "/pesanan", label: "Pesanan saya" },
  { href: "/mitra/permintaan", label: "Ruang mitra" },
  { href: "/bisnis", label: "Bisnis" },
  { href: "/akun/privasi", label: "Privasi" },
  { href: "/mitra", label: "Jadi mitra" },
]

export async function SiteHeader() {
  const supabase = await createClient()
  let user = null;
  try {
    const { data } = await supabase.auth.getUser();
    user = data.user;
  } catch (error) {
    console.error("Failed to fetch user in SiteHeader:", error);
  }

  return (
    <header className="sticky top-0 z-50 border-b border-border/70 bg-background/88 backdrop-blur-xl">
      <div className="container flex h-18 items-center justify-between gap-4 py-3">
        <Logo />
        <nav aria-label="Navigasi utama" className="hidden items-center gap-1 md:flex">
          {links.map((link) => (
            <Link key={link.href} href={link.href} className="rounded-md px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
              {link.label}
            </Link>
          ))}
        </nav>
        <div className="flex items-center gap-1.5">
          <ThemeToggle />
          {user ? (
            <div className="hidden sm:flex items-center gap-2">
              <Link href="/beranda" className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "text-primary font-semibold")}>Dashboard</Link>
              <form action="/auth/signout" method="POST">
                <button type="submit" className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "px-2")} aria-label="Keluar">
                  <LogOut className="size-4" />
                </button>
              </form>
            </div>
          ) : (
            <Link href="/masuk" className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "hidden sm:inline-flex")}>Masuk</Link>
          )}
          
          <Link href="/cari" className={cn(buttonVariants({ size: "sm" }), "hidden sm:inline-flex")}>Cari jasa</Link>
          
          <details className="group relative md:hidden">
            <summary className="grid size-11 cursor-pointer list-none place-items-center rounded-md hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" aria-label="Buka menu navigasi">
              <Menu className="size-5" aria-hidden="true" />
            </summary>
            <div className="absolute right-0 top-12 w-64 rounded-lg border bg-card p-2 shadow-float">
              <nav aria-label="Navigasi seluler" className="grid">
                {links.map((link) => <Link key={link.href} href={link.href} className="rounded-md px-4 py-3 text-sm font-medium hover:bg-accent">{link.label}</Link>)}
                <div className="mt-2 grid grid-cols-2 gap-2 border-t pt-2">
                  {user ? (
                    <form action="/auth/signout" method="POST" className="col-span-2">
                      <button type="submit" className={cn(buttonVariants({ variant: "outline", size: "sm" }), "w-full")}>Keluar</button>
                    </form>
                  ) : (
                    <Link href="/masuk" className={buttonVariants({ variant: "outline", size: "sm" })}>Masuk</Link>
                  )}
                  <Link href="/cari" className={buttonVariants({ size: "sm", className: "col-span-2 mt-2" })}>Cari jasa</Link>
                </div>
              </nav>
            </div>
          </details>
        </div>
      </div>
    </header>
  )
}
