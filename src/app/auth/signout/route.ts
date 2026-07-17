import { createClient } from "@/lib/supabase/server"
import { NextResponse } from "next/server"

export async function POST(request: Request) {
  try {
    const supabase = await createClient()
    await supabase.auth.signOut()
  } catch (error) {
    console.error("Error signing out:", error)
  }
  
  return NextResponse.redirect(new URL("/", request.url), { status: 303 })
}
