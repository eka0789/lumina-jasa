"use client"

import { Moon, Sun } from "lucide-react"
import { useTheme } from "next-themes"
import { Button } from "@/components/ui/button"

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme()
  const nextTheme = resolvedTheme === "dark" ? "light" : "dark"

  return (
    <Button variant="ghost" size="icon" onClick={() => setTheme(nextTheme)} aria-label={`Gunakan tema ${nextTheme === "dark" ? "gelap" : "terang"}`}>
      <Sun className="size-5 scale-100 dark:scale-0" aria-hidden="true" />
      <Moon className="absolute size-5 scale-0 dark:scale-100" aria-hidden="true" />
    </Button>
  )
}
