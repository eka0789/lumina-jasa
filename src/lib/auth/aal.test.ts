import { describe, expect, it } from "vitest"
import { hasAal2, requiresAal2 } from "@/lib/auth/aal"

describe("AAL2 route policy", () => {
  it.each(["/admin", "/admin/pengguna", "/operasional", "/keuangan/refund"])(
    "protects %s",
    (path) => expect(requiresAal2(path)).toBe(true),
  )

  it.each(["/", "/masuk", "/keamanan/mfa", "/administrasi"])(
    "does not overmatch %s",
    (path) => expect(requiresAal2(path)).toBe(false),
  )

  it("only accepts aal2", () => {
    expect(hasAal2("aal2")).toBe(true)
    expect(hasAal2("aal1")).toBe(false)
    expect(hasAal2(null)).toBe(false)
  })
})
