import { createServerClient } from "@supabase/ssr"
import { NextResponse, type NextRequest } from "next/server"
import { hasAal2, requiresAal2 } from "@/lib/auth/aal"

export async function updateSession(request: NextRequest) {
  const requestId = request.headers.get("x-request-id") ?? crypto.randomUUID()
  const requestHeaders = new Headers(request.headers)
  requestHeaders.set("x-request-id", requestId)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  if (!url || !key) {
    const unconfiguredResponse = NextResponse.next({ request: { headers: requestHeaders } })
    unconfiguredResponse.headers.set("x-request-id", requestId)
    return unconfiguredResponse
  }

  let response = NextResponse.next({ request: { headers: requestHeaders } })
  const supabase = createServerClient(url, key, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (cookiesToSet) => {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
        response = NextResponse.next({ request: { headers: requestHeaders } })
        cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options))
      },
    },
  })

  const { data: { user } } = await supabase.auth.getUser()
  if (user && requiresAal2(request.nextUrl.pathname)) {
    const { data } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
    if (!hasAal2(data?.currentLevel)) {
      const mfaUrl = request.nextUrl.clone()
      mfaUrl.pathname = "/keamanan/mfa"
      mfaUrl.search = ""
      mfaUrl.searchParams.set("next", `${request.nextUrl.pathname}${request.nextUrl.search}`)
      const redirect = NextResponse.redirect(mfaUrl)
      response.cookies.getAll().forEach((cookie) => redirect.cookies.set(cookie))
      redirect.headers.set("x-request-id", requestId)
      return redirect
    }
  }
  response.headers.set("x-request-id", requestId)
  return response
}
