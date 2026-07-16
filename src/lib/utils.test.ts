import { describe, expect, it } from "vitest"
import { cn, formatRupiah } from "@/lib/utils"

describe("utils", () => {
  it("merges conflicting Tailwind classes", () => {
    expect(cn("px-2", "px-4", false && "hidden")).toBe("px-4")
  })

  it("formats integer rupiah", () => {
    expect(formatRupiah(250000)).toContain("250.000")
  })
})
