"use client"

import Image from "next/image"
import { useCallback, useEffect, useState } from "react"
import { AlertCircle, CheckCircle2, KeyRound, LoaderCircle, ShieldCheck } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { createClient } from "@/lib/supabase/client"

type TotpFactor = { id: string; friendly_name?: string; status: "verified" | "unverified" }
type Enrollment = { id: string; qrCode: string; secret: string }

export function MfaSettings({ nextPath = "/" }: { nextPath?: string }) {
  const [factors, setFactors] = useState<TotpFactor[]>([])
  const [enrollment, setEnrollment] = useState<Enrollment | null>(null)
  const [code, setCode] = useState("")
  const [currentLevel, setCurrentLevel] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(true)

  const refresh = useCallback(async () => {
    const supabase = createClient()
    if (!supabase) {
      setError("Supabase belum dikonfigurasi pada environment ini.")
      setBusy(false)
      return
    }
    const [{ data: factorData, error: factorError }, { data: aalData }] = await Promise.all([
      supabase.auth.mfa.listFactors(),
      supabase.auth.mfa.getAuthenticatorAssuranceLevel(),
    ])
    if (factorError) setError("Status MFA belum dapat dimuat.")
    setFactors((factorData?.totp ?? []) as TotpFactor[])
    setCurrentLevel(aalData?.currentLevel ?? null)
    setBusy(false)
  }, [])

  useEffect(() => { void refresh() }, [refresh])

  async function startEnrollment() {
    setBusy(true); setError(null); setMessage(null)
    const supabase = createClient()
    if (!supabase) return setBusy(false)
    const { data, error: enrollError } = await supabase.auth.mfa.enroll({
      factorType: "totp",
      friendlyName: `Lumina Jasa - ${new Date().getTime()}`,
    })
    if (enrollError) {
      console.error("MFA Enroll Error:", enrollError)
      setError(`Authenticator belum dapat didaftarkan. Coba lagi. (${enrollError.message})`)
    }
    else setEnrollment({ id: data.id, qrCode: data.totp.qr_code, secret: data.totp.secret })
    setBusy(false)
  }

  async function verify() {
    if (!enrollment || !/^\d{6}$/.test(code)) {
      setError("Masukkan kode 6 digit dari aplikasi authenticator.")
      return
    }
    setBusy(true); setError(null)
    const supabase = createClient()
    if (!supabase) return setBusy(false)
    const { error: verifyError } = await supabase.auth.mfa.challengeAndVerify({
      factorId: enrollment.id,
      code,
    })
    if (verifyError) {
      setError("Kode tidak valid atau sudah kedaluwarsa.")
      setBusy(false)
      return
    }
    setEnrollment(null); setCode(""); setMessage("MFA aktif dan sesi ini telah mencapai AAL2.")
    await refresh()
  }

  async function challenge(factorId: string) {
    if (!/^\d{6}$/.test(code)) return setError("Masukkan kode 6 digit dari aplikasi authenticator.")
    setBusy(true); setError(null)
    const supabase = createClient()
    if (!supabase) return setBusy(false)
    const { error: challengeError } = await supabase.auth.mfa.challengeAndVerify({ factorId, code })
    if (challengeError) setError("Kode tidak valid atau sudah kedaluwarsa.")
    else window.location.assign(nextPath.startsWith("/") ? nextPath : "/")
    setBusy(false)
  }

  const verifiedFactor = factors.find((factor) => factor.status === "verified")

  if (busy && factors.length === 0 && !enrollment) {
    return <div role="status" className="flex items-center gap-2 text-sm text-muted-foreground"><LoaderCircle className="size-4 animate-spin motion-reduce:animate-none" />Memuat keamanan akun…</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start gap-3 rounded-lg border bg-muted/40 p-4">
        <ShieldCheck className="mt-0.5 size-5 shrink-0 text-primary" />
        <div><p className="font-semibold">Status sesi: {currentLevel === "aal2" ? "AAL2" : "AAL1"}</p><p className="mt-1 text-sm text-muted-foreground">Aksi staf, refund, dan perubahan pembayaran memerlukan verifikasi dua langkah.</p></div>
      </div>

      {error && <div role="alert" className="flex gap-2 rounded-md border border-destructive/20 bg-destructive/5 p-3 text-sm text-destructive"><AlertCircle className="mt-0.5 size-4 shrink-0" />{error}</div>}
      {message && <div role="status" className="flex gap-2 rounded-md border border-primary/20 bg-primary/5 p-3 text-sm text-primary"><CheckCircle2 className="mt-0.5 size-4 shrink-0" />{message}</div>}

      {enrollment ? (
        <section aria-labelledby="enroll-title" className="space-y-4">
          <div><h2 id="enroll-title" className="font-semibold">Pindai kode QR</h2><p className="mt-1 text-sm text-muted-foreground">Gunakan aplikasi authenticator, lalu masukkan kode yang muncul.</p></div>
          <div className="flex justify-center rounded-lg border bg-white p-4"><img src={enrollment.qrCode} alt="Kode QR untuk mengaktifkan MFA" width={192} height={192} className="size-48" /></div>
          <details className="text-sm"><summary className="cursor-pointer font-semibold">Tidak dapat memindai?</summary><p className="mt-2 break-all rounded-md bg-muted p-3 font-mono text-xs">{enrollment.secret}</p></details>
          <div className="space-y-2"><label htmlFor="totp-code" className="text-sm font-semibold">Kode verifikasi 6 digit</label><Input id="totp-code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} value={code} onChange={(event) => setCode(event.target.value.replace(/\D/g, ""))} /></div>
          <Button className="w-full" onClick={verify} disabled={busy}>{busy && <LoaderCircle className="size-4 animate-spin motion-reduce:animate-none" />}Aktifkan MFA</Button>
        </section>
      ) : verifiedFactor && currentLevel !== "aal2" ? (
        <section aria-labelledby="verify-title" className="space-y-4">
          <div><h2 id="verify-title" className="font-semibold">Verifikasi sesi</h2><p className="mt-1 text-sm text-muted-foreground">Masukkan kode authenticator untuk melanjutkan ke area sensitif.</p></div>
          <div className="space-y-2"><label htmlFor="challenge-code" className="text-sm font-semibold">Kode verifikasi 6 digit</label><Input id="challenge-code" inputMode="numeric" autoComplete="one-time-code" maxLength={6} value={code} onChange={(event) => setCode(event.target.value.replace(/\D/g, ""))} /></div>
          <Button className="w-full" onClick={() => challenge(verifiedFactor.id)} disabled={busy}><KeyRound className="size-4" />Verifikasi dan lanjutkan</Button>
        </section>
      ) : verifiedFactor ? (
        <div className="flex items-center gap-3 rounded-lg border border-primary/20 bg-primary/5 p-4 text-sm"><CheckCircle2 className="size-5 text-primary" /><span>Authenticator aktif. Sesi Anda siap untuk aksi sensitif.</span></div>
      ) : (
        <Button className="w-full" onClick={startEnrollment} disabled={busy}><KeyRound className="size-4" />Siapkan authenticator</Button>
      )}
    </div>
  )
}
