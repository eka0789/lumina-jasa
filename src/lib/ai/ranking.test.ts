import { describe, expect, it } from "vitest"
import { rankProviders, type RankableProvider } from "@/lib/ai/ranking"

const providers: RankableProvider[] = [
  { id: "popular", name: "Populer", rating: 4.9, reviewCount: 80, completedJobs: 300, responseRate: 97, areas: ["Depok"], services: [{ name: "Listrik", category: "Rumah", title: "Teknisi listrik" }] },
  { id: "relevant", name: "Relevan", rating: 4.5, reviewCount: 20, completedJobs: 50, responseRate: 88, areas: ["Jakarta Selatan"], services: [{ name: "Servis AC", category: "Pendingin", title: "Perbaikan AC" }] },
]

describe("interpretable provider ranking", () => {
  it("prioritizes strong service relevance and exposes reason codes", () => {
    const ranked = rankProviders(providers, "servis ac", "Jakarta Selatan")
    expect(ranked[0]?.provider.id).toBe("relevant")
    expect(ranked[0]?.reasons).toContain("Layanan cocok dengan pencarian")
    expect(ranked[0]?.reasons).toContain("Melayani area pilihan")
  })

  it("is deterministic and degrades to catalog popularity without a query", () => {
    expect(rankProviders(providers, "")[0]?.provider.id).toBe("popular")
    expect(rankProviders(providers, "")[0]?.mode).toBe("deterministic_fallback")
  })
})
