import { describe, expect, it } from "vitest"
import { getNextBookingAction } from "@/lib/booking-workflow"

describe("booking workflow presentation", () => {
  it("offers only the next provider action", () => {
    expect(getNextBookingAction("confirmed", true)?.status).toBe("accepted")
    expect(getNextBookingAction("in_progress", true)?.status).toBe("provider_completed")
  })

  it("offers customer confirmation only after provider completion", () => {
    expect(getNextBookingAction("provider_completed", false)?.status).toBe("customer_confirmed")
    expect(getNextBookingAction("in_progress", false)).toBeNull()
  })

  it("does not expose provider transitions to customers", () => {
    expect(getNextBookingAction("confirmed", false)).toBeNull()
  })
})
