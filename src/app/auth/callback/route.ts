import { NextResponse, type NextRequest } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code")
  const next = request.nextUrl.searchParams.get("next") ?? "/"
  const safeNext = next.startsWith("/") && !next.startsWith("//") ? next : "/"

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      if (safeNext === "/") {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
          if ((roles ?? []).some(r => ["admin", "super_admin", "support", "compliance"].includes(r.role))) {
            return NextResponse.redirect(new URL("/admin", request.url))
          }
        }
        return NextResponse.redirect(new URL("/beranda", request.url))
      }
      return NextResponse.redirect(new URL(safeNext, request.url))
    }
  }

  return NextResponse.redirect(new URL("/masuk?error=callback", request.url))
}
