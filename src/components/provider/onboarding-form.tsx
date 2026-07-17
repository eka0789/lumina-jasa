"use client"

import { useState, type ReactNode } from "react"
import Link from "next/link"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { AlertCircle, CheckCircle2, LoaderCircle } from "lucide-react"
import { Button, buttonVariants } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import type { CatalogServiceOption } from "@/lib/catalog"
import { createClient } from "@/lib/supabase/client"
import { cn } from "@/lib/utils"

const schema = z.object({
  displayName: z.string().min(3, "Nama penyedia minimal 3 karakter.").max(80),
  slug: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Gunakan huruf kecil, angka, dan tanda hubung."),
  bio: z.string().min(30, "Ceritakan keahlian Anda dalam minimal 30 karakter.").max(600),
  verificationKind: z.enum(["kyc", "kyb"]), serviceId: z.string().regex(/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/, "Pilih kategori layanan yang valid."),
  listingTitle: z.string().min(5, "Judul layanan minimal 5 karakter.").max(100),
  pricingType: z.enum(["fixed", "hourly", "from", "quote"]),
  basePrice: z.coerce.number().int().min(0).max(1_000_000_000),
  coverage: z.string().min(3, "Masukkan minimal satu kota atau area."), radiusKm: z.coerce.number().min(1).max(200),
  weekdays: z.array(z.coerce.number().int().min(0).max(6)).min(1, "Pilih minimal satu hari."),
  startsAt: z.string().regex(/^\d{2}:\d{2}$/), endsAt: z.string().regex(/^\d{2}:\d{2}$/),
}).refine((value) => value.startsAt < value.endsAt, { path: ["endsAt"], message: "Jam selesai harus setelah jam mulai." })

type FormInput = z.input<typeof schema>
type Values = z.output<typeof schema>
const days = [{ value: 1, label: "Sen" }, { value: 2, label: "Sel" }, { value: 3, label: "Rab" }, { value: 4, label: "Kam" }, { value: 5, label: "Jum" }, { value: 6, label: "Sab" }, { value: 0, label: "Min" }]

export function ProviderOnboardingForm({ services }: { services: CatalogServiceOption[] }) {
  const [error, setError] = useState<string | null>(null)
  const [submitted, setSubmitted] = useState(false)
  const [documentFile, setDocumentFile] = useState<File | null>(null)
  const form = useForm<FormInput, unknown, Values>({ resolver: zodResolver(schema), defaultValues: { displayName: "", slug: "", bio: "", verificationKind: "kyc", serviceId: services[0]?.id ?? "", listingTitle: "", pricingType: "from", basePrice: 0, coverage: "", radiusKm: 15, weekdays: [1, 2, 3, 4, 5], startsAt: "08:00", endsAt: "17:00" } })

  function makeSlug() {
    if (form.getValues("slug")) return
    form.setValue("slug", form.getValues("displayName").toLocaleLowerCase("id-ID").normalize("NFKD").replace(/[^a-z0-9\s-]/g, "").trim().replace(/\s+/g, "-"), { shouldValidate: true })
  }

  async function onSubmit(values: Values) {
    setError(null)
    const supabase = createClient()
    if (!supabase) return setError("Supabase belum dikonfigurasi.")
    if (!documentFile || !["application/pdf", "image/jpeg", "image/png"].includes(documentFile.type) || documentFile.size > 8 * 1024 * 1024) {
      return setError("Unggah PDF, JPG, atau PNG berukuran maksimal 8 MB.")
    }
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return setError("Sesi berakhir. Silakan masuk kembali.")
    const extension = documentFile.type === "application/pdf" ? "pdf" : documentFile.type === "image/png" ? "png" : "jpg"
    const documentPath = `${user.id}/${crypto.randomUUID()}.${extension}`
    const { error: uploadError } = await supabase.storage.from("compliance-documents").upload(documentPath, documentFile, { contentType: documentFile.type, upsert: false })
    if (uploadError) return setError("Dokumen verifikasi belum dapat diunggah.")
    const { error: submitError } = await supabase.rpc("submit_provider_onboarding", {
      provider_display_name: values.displayName, provider_slug: values.slug, provider_bio: values.bio,
      verification_kind: values.verificationKind, catalog_service_id: values.serviceId,
      listing_title: values.listingTitle, listing_pricing_type: values.pricingType, listing_base_price: values.basePrice || null,
      coverage_labels: values.coverage.split(",").map((item) => item.trim()).filter(Boolean), coverage_radius_km: values.radiusKm,
      available_weekdays: values.weekdays, available_starts_at: values.startsAt, available_ends_at: values.endsAt,
      verification_document_path: documentPath, verification_document_name: documentFile.name,
      verification_document_mime: documentFile.type, verification_document_size: documentFile.size,
      verification_document_type: values.verificationKind === "kyc" ? "identity" : "business_registration",
      request_correlation_id: crypto.randomUUID(),
    })
    if (submitError) { await supabase.storage.from("compliance-documents").remove([documentPath]); setError(submitError.code === "23505" ? "Alamat profil sudah digunakan. Pilih slug lain." : "Pendaftaran belum dapat dikirim. Periksa data dan coba lagi."); return }
    setSubmitted(true)
  }

  if (submitted) return <div role="status" className="rounded-xl border border-success/20 bg-success/5 p-6 text-center"><CheckCircle2 className="mx-auto size-10 text-success" /><h2 className="mt-4 text-xl font-bold">Pendaftaran masuk antrean tinjauan</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">Tim verifikasi akan menilai identitas atau badan usaha Anda. Profil publik aktif hanya setelah disetujui.</p><Link href="/" className={cn(buttonVariants({ variant: "outline" }), "mt-5")}>Kembali ke beranda</Link></div>

  const fieldError = (name: keyof Values) => form.formState.errors[name]?.message?.toString()
  return <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8" noValidate>
    <fieldset className="space-y-4"><legend className="text-lg font-bold">1. Profil penyedia</legend><div className="grid gap-4 sm:grid-cols-2"><Field label="Nama publik" id="displayName" error={fieldError("displayName")}><Input id="displayName" {...form.register("displayName")} onBlur={makeSlug} /></Field><Field label="Alamat profil" id="slug" hint="Contoh: budi-teknik" error={fieldError("slug")}><Input id="slug" {...form.register("slug")} /></Field></div><Field label="Tentang keahlian" id="bio" error={fieldError("bio")}><textarea id="bio" rows={4} className="w-full rounded-md border bg-background px-3 py-2 text-sm focus-visible:ring-2 focus-visible:ring-ring" {...form.register("bio")} /></Field><div className="space-y-2"><span className="text-sm font-semibold">Jenis verifikasi</span><div className="grid gap-3 sm:grid-cols-2"><label className="flex cursor-pointer gap-3 rounded-lg border p-4 text-sm"><input type="radio" value="kyc" className="mt-1 accent-[hsl(var(--primary))]" {...form.register("verificationKind")} /><span><strong className="block">Individu (KYC)</strong><span className="text-muted-foreground">Untuk profesional perseorangan.</span></span></label><label className="flex cursor-pointer gap-3 rounded-lg border p-4 text-sm"><input type="radio" value="kyb" className="mt-1 accent-[hsl(var(--primary))]" {...form.register("verificationKind")} /><span><strong className="block">Badan usaha (KYB)</strong><span className="text-muted-foreground">Untuk perusahaan atau usaha berbadan hukum.</span></span></label></div></div><Field label="Dokumen verifikasi" id="verificationDocument" hint="PDF, JPG, atau PNG · maksimal 8 MB"><Input id="verificationDocument" type="file" accept="application/pdf,image/jpeg,image/png" onChange={(event) => setDocumentFile(event.target.files?.[0] ?? null)} required /></Field></fieldset>
    <fieldset className="space-y-4"><legend className="text-lg font-bold">2. Layanan utama</legend><div className="grid gap-4 sm:grid-cols-2"><Field label="Kategori layanan" id="serviceId" error={fieldError("serviceId")}><select id="serviceId" className="min-h-11 w-full rounded-md border bg-background px-3 text-sm" {...form.register("serviceId")}>{services.map((service) => <option key={service.id} value={service.id}>{service.category} · {service.name}</option>)}</select></Field><Field label="Judul listing" id="listingTitle" error={fieldError("listingTitle")}><Input id="listingTitle" placeholder="Servis dan perawatan AC" {...form.register("listingTitle")} /></Field><Field label="Model harga" id="pricingType"><select id="pricingType" className="min-h-11 w-full rounded-md border bg-background px-3 text-sm" {...form.register("pricingType")}><option value="from">Mulai dari</option><option value="fixed">Harga tetap</option><option value="hourly">Per jam</option><option value="quote">Penawaran manual</option></select></Field><Field label="Harga awal (rupiah)" id="basePrice" error={fieldError("basePrice")}><Input id="basePrice" type="number" min={0} step={10000} {...form.register("basePrice")} /></Field></div></fieldset>
    <fieldset className="space-y-4"><legend className="text-lg font-bold">3. Area dan ketersediaan</legend><div className="grid gap-4 sm:grid-cols-[1fr_160px]"><Field label="Kota/area layanan" id="coverage" hint="Pisahkan beberapa area dengan koma" error={fieldError("coverage")}><Input id="coverage" placeholder="Jakarta Selatan, Depok" {...form.register("coverage")} /></Field><Field label="Radius (km)" id="radiusKm" error={fieldError("radiusKm")}><Input id="radiusKm" type="number" min={1} max={200} {...form.register("radiusKm")} /></Field></div><div><span className="text-sm font-semibold">Hari tersedia</span><div className="mt-2 flex flex-wrap gap-2">{days.map((day) => <label key={day.value} className="flex min-h-11 cursor-pointer items-center gap-2 rounded-md border px-3 text-sm"><input type="checkbox" value={day.value} className="accent-[hsl(var(--primary))]" {...form.register("weekdays", { valueAsNumber: true })} />{day.label}</label>)}</div>{fieldError("weekdays") && <p role="alert" className="mt-2 text-sm text-destructive">{fieldError("weekdays")}</p>}</div><div className="grid gap-4 sm:grid-cols-2"><Field label="Mulai" id="startsAt"><Input id="startsAt" type="time" {...form.register("startsAt")} /></Field><Field label="Selesai" id="endsAt" error={fieldError("endsAt")}><Input id="endsAt" type="time" {...form.register("endsAt")} /></Field></div></fieldset>
    {error && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="mt-0.5 size-4 shrink-0" />{error}</div>}
    <Button type="submit" size="lg" className="w-full" disabled={form.formState.isSubmitting || services.length === 0}>{form.formState.isSubmitting && <LoaderCircle className="size-4 animate-spin motion-reduce:animate-none" />}Kirim untuk verifikasi</Button>
  </form>
}

function Field({ label, id, hint, error, children }: { label: string; id: string; hint?: string; error?: string; children: ReactNode }) {
  return <div className="space-y-2"><label htmlFor={id} className="text-sm font-semibold">{label}</label>{children}{hint && !error && <p className="text-xs text-muted-foreground">{hint}</p>}{error && <p role="alert" className="text-sm text-destructive">{error}</p>}</div>
}
