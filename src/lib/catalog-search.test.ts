import { describe, expect, it } from "vitest"
import { matchesCatalogQuery, normalizeCatalogTerm } from "@/lib/catalog-search"

describe("catalog search", () => {
  it("normalizes case, whitespace, and diacritics", () => {
    expect(normalizeCatalogTerm("  TÉKNISI AC ")).toBe("teknisi ac")
  })

  it("matches provider service and area fields", () => {
    const fields = ["Budi Teknik", "Servis AC", "Jakarta Selatan"]
    expect(matchesCatalogQuery(fields, "servis")).toBe(true)
    expect(matchesCatalogQuery(fields, "jakarta selatan")).toBe(true)
    expect(matchesCatalogQuery(fields, "desain logo")).toBe(false)
  })

  it("treats an empty query as all providers", () => {
    expect(matchesCatalogQuery([], "  ")).toBe(true)
  })
})
