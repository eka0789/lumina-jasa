import React from "react"
import { cleanup, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"
import { SiteHeader } from "@/components/site-header"

vi.mock("next-themes", () => ({ useTheme: () => ({ resolvedTheme: "light", setTheme: vi.fn() }) }))
vi.mock("next/headers", () => ({ cookies: vi.fn().mockResolvedValue({ getAll: () => [], set: vi.fn() }) }))
vi.mock("next/navigation", () => ({ redirect: vi.fn(), useRouter: vi.fn() }))
vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn().mockResolvedValue({
    auth: { getUser: vi.fn().mockResolvedValue({ data: { user: null } }) },
  }),
}))
afterEach(cleanup)

async function renderAsync(ui: React.ReactElement) {
  const Resolved = await (ui.type as () => Promise<React.ReactElement>)()
  return render(Resolved)
}

describe("primary navigation accessibility", () => {
  it("exposes named desktop and mobile navigation landmarks", async () => {
    await renderAsync(<SiteHeader />)
    expect(screen.getByRole("navigation", { name: "Navigasi utama" })).toBeInTheDocument()
    expect(screen.getByRole("navigation", { name: "Navigasi seluler" })).toBeInTheDocument()
  })

  it("provides accessible names for icon-only controls", async () => {
    await renderAsync(<SiteHeader />)
    expect(screen.getByRole("button", { name: "Gunakan tema gelap" })).toBeInTheDocument()
    expect(screen.getByLabelText("Buka menu navigasi")).toBeInTheDocument()
  })
})
