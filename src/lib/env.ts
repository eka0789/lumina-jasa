import { z } from "zod"

const publicEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(20),
})

export type PublicEnv = z.infer<typeof publicEnvSchema>

export function getPublicEnv(): PublicEnv | null {
  const parsed = publicEnvSchema.safeParse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  })
  return parsed.success ? parsed.data : null
}

export function requirePublicEnv(): PublicEnv {
  const env = getPublicEnv()
  if (!env) throw new Error("Konfigurasi Supabase belum lengkap. Periksa .env.example.")
  return env
}
