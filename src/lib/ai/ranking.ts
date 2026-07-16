import { normalizeCatalogTerm } from "@/lib/catalog-search"

export type RankableProvider = {
  id: string
  name: string
  rating: number
  reviewCount: number
  completedJobs: number
  responseRate: number
  areas: string[]
  services: Array<{ name: string; category: string; title: string }>
}

export type RankedProvider<T> = { provider: T; score: number; reasons: string[]; mode: "deterministic_fallback" }

export function rankProviders<T extends RankableProvider>(providers: T[], query: string, area = ""): RankedProvider<T>[] {
  const term = normalizeCatalogTerm(query)
  const areaTerm = normalizeCatalogTerm(area)
  return providers.map((provider) => {
    const serviceText = normalizeCatalogTerm(provider.services.flatMap((service) => [service.name, service.category, service.title]).join(" "))
    const areaText = normalizeCatalogTerm(provider.areas.join(" "))
    const reasons: string[] = []
    let score = Math.min(provider.rating / 5, 1) * 25 + Math.min(provider.responseRate / 100, 1) * 20 + Math.min(Math.log10(provider.completedJobs + 1) / 3, 1) * 15
    if (term && serviceText.includes(term)) { score += 30; reasons.push("Layanan cocok dengan pencarian") }
    if (areaTerm && areaText.includes(areaTerm)) { score += 10; reasons.push("Melayani area pilihan") }
    if (provider.rating >= 4.7 && provider.reviewCount >= 10) reasons.push("Reputasi terverifikasi kuat")
    if (provider.responseRate >= 90) reasons.push("Respons cepat")
    if (reasons.length === 0) reasons.push("Urutan populer berbasis data katalog")
    return { provider, score: Math.round(score * 100) / 100, reasons: reasons.slice(0, 3), mode: "deterministic_fallback" as const }
  }).sort((a, b) => b.score - a.score || a.provider.id.localeCompare(b.provider.id))
}
