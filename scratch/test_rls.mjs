import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJh...'

const supabase = createClient(supabaseUrl, supabaseKey)

async function test() {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'customer@example.com',
    password: 'password123'
  })
  
  if (error) {
    console.error("Auth error:", error)
    return
  }
  
  console.log("Logged in:", data.user.id)
  
  const { data: bookings, error: bookingsError } = await supabase.from("bookings").select("id,status,scheduled_start,total_amount,job:jobs(title),provider:providers(display_name)").eq("customer_id", data.user.id).order("scheduled_start", { ascending: false });
  
  if (bookingsError) {
    console.error("Query error:", bookingsError)
  } else {
    console.log("Query success:", bookings.length, "bookings")
  }
}

test()
