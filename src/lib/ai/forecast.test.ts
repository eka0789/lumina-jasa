import { describe, expect, it } from "vitest"
import { forecastDemand, weightedAbsolutePercentageError } from "@/lib/ai/forecast"

describe("demand forecast baseline", () => {
  it("returns an ordered interval and pinned model version", () => {
    expect(forecastDemand([2, 4, 3, 5], 7)).toEqual({ p10: 16, p50: 25, p90: 36, modelVersion: "historical-baseline-v1" })
  })

  it("degrades safely for missing history", () => {
    expect(forecastDemand([])).toEqual({ p10: 0, p50: 0, p90: 0, modelVersion: "historical-baseline-v1" })
  })

  it("computes WAPE without dividing by an empty demand series", () => {
    expect(weightedAbsolutePercentageError([10, 20], [8, 22])).toBeCloseTo(4 / 30)
    expect(weightedAbsolutePercentageError([0, 0], [1, 1])).toBeNull()
  })
})
