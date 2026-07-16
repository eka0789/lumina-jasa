import { describe, expect, it } from "vitest"
import { buildContentSecurityPolicy, staticSecurityHeaders } from "@/lib/security/headers"

describe("launch security headers", () => {
  it("builds a nonce CSP with restricted framing and Supabase connectivity", () => {
    const policy = buildContentSecurityPolicy("nonce-value", "https://example.supabase.co", true)
    expect(policy).toContain("script-src 'self' 'nonce-nonce-value' 'strict-dynamic'")
    expect(policy).toContain("connect-src 'self' https://example.supabase.co wss://example.supabase.co")
    expect(policy).toContain("frame-ancestors 'none'")
    expect(policy).toContain("upgrade-insecure-requests")
    expect(policy).not.toContain("unsafe-eval")
  })

  it("keeps the baseline anti-clickjacking and browser-isolation headers", () => {
    expect(Object.fromEntries(staticSecurityHeaders.map(({ key, value }) => [key, value]))).toMatchObject({
      "X-Frame-Options": "DENY",
      "X-Content-Type-Options": "nosniff",
      "Cross-Origin-Opener-Policy": "same-origin",
    })
  })
})
