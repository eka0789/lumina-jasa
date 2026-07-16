import "server-only"

import { getPublicEnv } from "@/lib/env"
import { matchesCatalogQuery } from "@/lib/catalog-search"
import { createClient } from "@/lib/supabase/server"

export type CatalogService = {
  name: string
  category: string
  title: string
  pricingType: string
  basePrice: number | null
}

export type CatalogAvailability = { weekday: number; startsAt: string; endsAt: string }
export type CatalogServiceOption = { id: string; name: string; category: string }

export type CatalogProvider = {
  id: string
  slug: string
  name: string
  initials: string
  bio: string
  rating: number
  reviewCount: number
  completedJobs: number
  responseRate: number
  areas: string[]
  radiusKm: number | null
  services: CatalogService[]
  availability: CatalogAvailability[]
}

const fallbackProviders: CatalogProvider[] = [
  { id: "sample-budi", slug: "budi-teknik", name: "Budi Teknik", initials: "BT", bio: "Teknisi perawatan rumah untuk AC, listrik ringan, dan perbaikan harian.", rating: 4.9, reviewCount: 128, completedJobs: 342, responseRate: 96, areas: ["Jakarta Selatan", "Depok"], radiusKm: 18, services: [{ name: "Servis AC", category: "Perbaikan rumah", title: "Servis dan perawatan AC", pricingType: "from", basePrice: 200000 }], availability: [{ weekday: 1, startsAt: "08:00", endsAt: "17:00" }, { weekday: 2, startsAt: "08:00", endsAt: "17:00" }] },
  { id: "sample-sejuk", slug: "sejuk-refrigerasi", name: "Sejuk Refrigerasi", initials: "SR", bio: "Spesialis AC dan sistem pendingin untuk rumah serta tempat usaha.", rating: 4.8, reviewCount: 94, completedJobs: 221, responseRate: 93, areas: ["Jakarta Timur", "Bekasi"], radiusKm: 22, services: [{ name: "Perbaikan pendingin", category: "AC & pendingin", title: "Perbaikan AC dan refrigerasi", pricingType: "from", basePrice: 250000 }], availability: [{ weekday: 1, startsAt: "09:00", endsAt: "18:00" }] },
  { id: "sample-andi", slug: "andi-pratama", name: "Andi Pratama", initials: "AP", bio: "Teknisi panggilan untuk pemeriksaan dan perbaikan cepat di lokasi.", rating: 4.8, reviewCount: 76, completedJobs: 184, responseRate: 91, areas: ["Tangerang Selatan"], radiusKm: 15, services: [{ name: "Teknisi panggilan", category: "Perbaikan rumah", title: "Kunjungan teknisi", pricingType: "from", basePrice: 180000 }], availability: [{ weekday: 6, startsAt: "08:00", endsAt: "15:00" }] },
]

const fallbackServices: CatalogServiceOption[] = [
  { id: "52000000-0000-0000-0000-000000000001", name: "Servis AC", category: "Perbaikan rumah" },
  { id: "52000000-0000-0000-0000-000000000002", name: "Perbaikan listrik", category: "Perbaikan rumah" },
  { id: "52000000-0000-0000-0000-000000000003", name: "Perbaikan pipa", category: "Perbaikan rumah" },
]

type RawProvider = {
  id: string
  slug: string
  display_name: string
  bio: string | null
  rating_avg: number | string
  rating_count: number
  completed_jobs: number
  response_rate: number | string
  service_area_labels: string[] | null
  service_radius_km: number | string | null
  provider_services: Array<{
    title: string
    pricing_type: string
    base_price: number | null
    service: { name: string; category: { name: string } | null } | null
  }>
  provider_availability: Array<{ weekday: number | null; starts_at: string | null; ends_at: string | null }>
}

function initials(name: string) {
  return name.split(/\s+/).slice(0, 2).map((part) => part[0]).join("").toUpperCase()
}

function mapProvider(provider: RawProvider): CatalogProvider {
  return {
    id: provider.id,
    slug: provider.slug,
    name: provider.display_name,
    initials: initials(provider.display_name),
    bio: provider.bio ?? "Penyedia jasa terverifikasi di Lumina Jasa.",
    rating: Number(provider.rating_avg),
    reviewCount: provider.rating_count,
    completedJobs: provider.completed_jobs,
    responseRate: Number(provider.response_rate),
    areas: provider.service_area_labels ?? [],
    radiusKm: provider.service_radius_km === null ? null : Number(provider.service_radius_km),
    services: provider.provider_services.map((listing) => ({
      name: listing.service?.name ?? listing.title,
      category: listing.service?.category?.name ?? "Layanan profesional",
      title: listing.title,
      pricingType: listing.pricing_type,
      basePrice: listing.base_price,
    })),
    availability: provider.provider_availability.flatMap((slot) =>
      slot.weekday === null || !slot.starts_at || !slot.ends_at ? [] : [{ weekday: slot.weekday, startsAt: slot.starts_at.slice(0, 5), endsAt: slot.ends_at.slice(0, 5) }],
    ),
  }
}

const providerSelect = `
  id, slug, display_name, bio, rating_avg, rating_count, completed_jobs, response_rate,
  service_area_labels, service_radius_km,
  provider_services!inner(title, pricing_type, base_price, service:services(name, category:categories(name))),
  provider_availability(weekday, starts_at, ends_at)
`

export async function getCatalogProviders(query = "") {
  if (!getPublicEnv()) return filterProviders(fallbackProviders, query)
  const supabase = await createClient()
  const { data, error } = await supabase.from("providers").select(providerSelect).eq("status", "active").eq("verification_status", "verified").eq("provider_services.status", "active").limit(24)
  if (error) throw new Error(`Katalog tidak dapat dimuat: ${error.message}`)
  return filterProviders(((data ?? []) as unknown as RawProvider[]).map(mapProvider), query)
}

export async function getCatalogProvider(slug: string) {
  if (!getPublicEnv()) return fallbackProviders.find((provider) => provider.slug === slug) ?? null
  const supabase = await createClient()
  const { data, error } = await supabase.from("providers").select(providerSelect).eq("slug", slug).eq("status", "active").eq("verification_status", "verified").eq("provider_services.status", "active").maybeSingle()
  if (error) throw new Error(`Profil penyedia tidak dapat dimuat: ${error.message}`)
  return data ? mapProvider(data as unknown as RawProvider) : null
}

function filterProviders(providers: CatalogProvider[], query: string) {
  return providers.filter((provider) => matchesCatalogQuery([provider.name, provider.bio, ...provider.areas, ...provider.services.flatMap((service) => [service.name, service.category, service.title])], query))
}

export async function getCatalogServiceOptions(): Promise<CatalogServiceOption[]> {
  if (!getPublicEnv()) return fallbackServices
  const supabase = await createClient()
  const { data, error } = await supabase.from("services").select("id, name, category:categories(name)").eq("status", "active").order("name")
  if (error) throw new Error(`Daftar layanan tidak dapat dimuat: ${error.message}`)
  return ((data ?? []) as unknown as Array<{ id: string; name: string; category: { name: string } | null }>).map((service) => ({ id: service.id, name: service.name, category: service.category?.name ?? "Layanan" }))
}
