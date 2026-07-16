import React from "react"
import { cleanup, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"
import { SiteHeader } from "@/components/site-header"

vi.mock("next-themes", () => ({ useTheme: () => ({ resolvedTheme: "light", setTheme: vi.fn() }) }))
afterEach(cleanup)

describe("primary navigation accessibility", () => {
  it("exposes named desktop and mobile navigation landmarks", () => {
    render(<SiteHeader />)
    expect(screen.getByRole("navigation", { name: "Navigasi utama" })).toBeInTheDocument()
    expect(screen.getByRole("navigation", { name: "Navigasi seluler" })).toBeInTheDocument()
  })

  it("provides accessible names for icon-only controls", () => {
    render(<SiteHeader />)
    expect(screen.getByRole("button", { name: "Gunakan tema gelap" })).toBeInTheDocument()
    expect(screen.getByLabelText("Buka menu navigasi")).toBeInTheDocument()
  })
})
