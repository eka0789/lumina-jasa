import { describe, expect, it, vi } from "vitest"
import { logEvent, sanitizeContext } from "@/lib/observability/logger"

describe("structured logger", () => {
  it("redacts sensitive context fields", () => {
    expect(sanitizeContext({ requestId: "req-1", authorization: "Bearer secret", paymentId: "pay-1" })).toEqual({
      requestId: "req-1",
      authorization: "[REDACTED]",
      paymentId: "[REDACTED]",
    })
  })

  it("emits JSON records", () => {
    const info = vi.spyOn(console, "info").mockImplementation(() => undefined)
    logEvent("info", "test.event", { requestId: "req-1" })
    expect(JSON.parse(String(info.mock.calls[0]?.[0]))).toMatchObject({ event: "test.event", requestId: "req-1" })
    info.mockRestore()
  })
})
