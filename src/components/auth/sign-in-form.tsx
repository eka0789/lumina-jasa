"use client"

import { useState } from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { AlertCircle, LoaderCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

const schema = z.object({
  email: z.string().email("Masukkan alamat email yang valid."),
  password: z.string().min(8, "Kata sandi minimal 8 karakter."),
})
type Values = z.infer<typeof schema>

export function SignInForm({ nextPath = "/" }: { nextPath?: string }) {
  const [serverError, setServerError] = useState<string | null>(null)
  const form = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { email: "", password: "" } })

  async function onSubmit(values: Values) {
    setServerError(null)
    const supabase = createClient()
    if (!supabase) {
      setServerError("Supabase belum dikonfigurasi pada environment ini.")
      return
    }
    const { error } = await supabase.auth.signInWithPassword(values)
    if (error) {
      setServerError("Email atau kata sandi tidak cocok.")
      return
    }
    window.location.assign(nextPath !== "/" ? nextPath : "/pesanan")
  }

  async function signInWithGoogle() {
    setServerError(null)
    const supabase = createClient()
    if (!supabase) return setServerError("Supabase belum dikonfigurasi pada environment ini.")
    const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(nextPath)}`
    const { error } = await supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo } })
    if (error) setServerError("Login Google belum dapat dimulai.")
  }

  return (
    <div className="space-y-5">
      <Button variant="outline" className="w-full" type="button" onClick={signInWithGoogle}>Lanjutkan dengan Google</Button>
      <div className="flex items-center gap-3 text-xs uppercase tracking-[0.15em] text-muted-foreground"><span className="h-px flex-1 bg-border" />atau email<span className="h-px flex-1 bg-border" /></div>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4" noValidate>
        <div className="space-y-2">
          <label htmlFor="email" className="text-sm font-semibold">Email</label>
          <Input id="email" type="email" autoComplete="email" aria-invalid={Boolean(form.formState.errors.email)} aria-describedby={form.formState.errors.email ? "email-error" : undefined} {...form.register("email")} />
          {form.formState.errors.email && <p id="email-error" role="alert" className="text-sm text-destructive">{form.formState.errors.email.message}</p>}
        </div>
        <div className="space-y-2">
          <div className="flex items-center justify-between"><label htmlFor="password" className="text-sm font-semibold">Kata sandi</label><a href="#" className="text-xs font-semibold text-primary hover:underline">Lupa kata sandi?</a></div>
          <Input id="password" type="password" autoComplete="current-password" aria-invalid={Boolean(form.formState.errors.password)} aria-describedby={form.formState.errors.password ? "password-error" : undefined} {...form.register("password")} />
          {form.formState.errors.password && <p id="password-error" role="alert" className="text-sm text-destructive">{form.formState.errors.password.message}</p>}
        </div>
        {serverError && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="mt-0.5 size-4 shrink-0" />{serverError}</div>}
        <Button className="w-full" type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting && <LoaderCircle className="size-4 animate-spin motion-reduce:animate-none" />} Masuk
        </Button>
      </form>
    </div>
  )
}
