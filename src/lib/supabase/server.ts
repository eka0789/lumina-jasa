import "server-only"

import { createServerClient } from "@supabase/ssr"
import { cookies } from "next/headers"
import { requirePublicEnv } from "@/lib/env"

export async function createClient() {
  const cookieStore = await cookies()
  const env = requirePublicEnv()

  return createServerClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (cookiesToSet) => {
        try {
          cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options))
        } catch {
          // Server Components cannot set cookies; middleware refreshes sessions.
        }
      },
    },
  })
}
