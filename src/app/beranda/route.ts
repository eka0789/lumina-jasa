import { NextResponse, type NextRequest } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function GET(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return NextResponse.redirect(new URL("/masuk", request.url))
  }

  // 1. Check platform roles (admin/staff)
  const { data: roles } = await supabase.from("user_roles").select("role").eq("user_id", user.id).is("revoked_at", null)
  const isStaff = (roles ?? []).some(r => 
    ["super_admin", "admin", "support", "finance", "compliance", "ai_moderator"].includes(r.role)
  )
  if (isStaff) {
    return NextResponse.redirect(new URL("/admin/kepercayaan", request.url))
  }

  // 2. Check provider roles
  const { data: provider } = await supabase.from("provider_members").select("provider_id").eq("user_id", user.id).eq("status", "active").limit(1)
  if (provider && provider.length > 0) {
    return NextResponse.redirect(new URL("/mitra/pesanan", request.url))
  }

  // 3. Check business roles
  const { data: business } = await supabase.from("business_members").select("business_id").eq("user_id", user.id).eq("status", "active").limit(1)
  if (business && business.length > 0) {
    return NextResponse.redirect(new URL("/bisnis", request.url))
  }

  // 4. Default fallback for standard customers
  return NextResponse.redirect(new URL("/pesanan", request.url))
}
