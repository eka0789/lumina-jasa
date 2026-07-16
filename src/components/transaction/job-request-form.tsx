"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { AlertCircle, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import type { CatalogServiceOption } from "@/lib/catalog"
import { createClient } from "@/lib/supabase/client"

const schema = z.object({ serviceId: z.string().uuid(), title: z.string().min(5), description: z.string().min(20), start: z.string().min(1), end: z.string().min(1), budgetMin: z.coerce.number().int().min(0), budgetMax: z.coerce.number().int().positive() }).refine((value) => value.budgetMax >= value.budgetMin, { path: ["budgetMax"], message: "Batas maksimal harus lebih besar." }).refine((value) => new Date(value.end) > new Date(value.start), { path: ["end"], message: "Waktu selesai harus setelah mulai." })
type InputValues = z.input<typeof schema>
type Values = z.output<typeof schema>

export function JobRequestForm({ services }: { services: CatalogServiceOption[] }) {
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)
  const form = useForm<InputValues, unknown, Values>({ resolver: zodResolver(schema), defaultValues: { serviceId: services[0]?.id ?? "", title: "", description: "", start: "", end: "", budgetMin: 0, budgetMax: 500000 } })
  async function onSubmit(values: Values) {
    setError(null); const supabase = createClient(); if (!supabase) return setError("Supabase belum dikonfigurasi.")
    const { data, error: rpcError } = await supabase.rpc("submit_job_request", { p_service_id: values.serviceId, p_title: values.title, p_description: values.description, p_requested_start: new Date(values.start).toISOString(), p_requested_end: new Date(values.end).toISOString(), p_budget_min: values.budgetMin, p_budget_max: values.budgetMax, p_idempotency_key: crypto.randomUUID() })
    if (rpcError || !data) return setError("Permintaan belum dapat dibuat. Periksa jadwal dan data Anda.")
    router.push(`/permintaan/${data}`); router.refresh()
  }
  const message = (name: keyof Values) => form.formState.errors[name]?.message?.toString()
  return <form className="space-y-6" onSubmit={form.handleSubmit(onSubmit)} noValidate>
    <Field label="Jenis layanan" id="serviceId" error={message("serviceId")}><select id="serviceId" className="min-h-11 w-full rounded-md border bg-background px-3 text-sm" {...form.register("serviceId")}>{services.map((service) => <option key={service.id} value={service.id}>{service.category} · {service.name}</option>)}</select></Field>
    <Field label="Judul kebutuhan" id="title" error={message("title")}><Input id="title" placeholder="AC kamar tidak dingin" {...form.register("title")} /></Field>
    <Field label="Jelaskan masalah dan hasil yang diharapkan" id="description" error={message("description")}><textarea id="description" rows={5} className="w-full rounded-md border bg-background px-3 py-2 text-sm" {...form.register("description")} /></Field>
    <div className="grid gap-4 sm:grid-cols-2"><Field label="Awal jendela jadwal" id="start" error={message("start")}><Input id="start" type="datetime-local" {...form.register("start")} /></Field><Field label="Akhir jendela jadwal" id="end" error={message("end")}><Input id="end" type="datetime-local" {...form.register("end")} /></Field></div>
    <div className="grid gap-4 sm:grid-cols-2"><Field label="Anggaran minimum" id="budgetMin" error={message("budgetMin")}><Input id="budgetMin" type="number" min={0} step={10000} {...form.register("budgetMin")} /></Field><Field label="Anggaran maksimum" id="budgetMax" error={message("budgetMax")}><Input id="budgetMax" type="number" min={0} step={10000} {...form.register("budgetMax")} /></Field></div>
    {error && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="size-4 shrink-0" />{error}</div>}
    <Button type="submit" size="lg" className="w-full" disabled={form.formState.isSubmitting}>{form.formState.isSubmitting && <LoaderCircle className="size-4 animate-spin" />}Cari penyedia</Button>
  </form>
}

function Field({ label, id, error, children }: { label: string; id: string; error?: string; children: React.ReactNode }) { return <div className="space-y-2"><label htmlFor={id} className="text-sm font-semibold">{label}</label>{children}{error && <p role="alert" className="text-sm text-destructive">{error}</p>}</div> }
