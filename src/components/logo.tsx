import Link from "next/link"
import { Sparkles } from "lucide-react"
import { cn } from "@/lib/utils"

export function Logo({ className }: { className?: string }) {
  return (
    <Link href="/" className={cn("inline-flex items-center gap-2.5 rounded-md font-bold tracking-tight focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring", className)}>
      <span className="grid size-9 place-items-center rounded-md bg-primary text-primary-foreground shadow-sm">
        <Sparkles className="size-4.5" aria-hidden="true" />
      </span>
      <span className="text-lg">Lumina <span className="text-primary">Jasa</span></span>
    </Link>
  )
}
