/// <reference path="./deno_env.d.ts" />
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const LIMIT = 100

serve(async (req) => {
  const syncKey = req.headers.get("x-sync-key")
  const wpSyncSecret = Deno.env.get("WP_SYNC_SECRET")

  if (!syncKey || syncKey !== wpSyncSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    })
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  if (!supabaseUrl || !supabaseServiceKey) {
    return new Response(
      JSON.stringify({ error: "Server configuration error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }

  const url = new URL(req.url)
  const lastSync = url.searchParams.get("last_sync") ?? "1970-01-01"
  const page = Math.max(0, parseInt(url.searchParams.get("page") ?? "0", 10))
  const from = page * LIMIT
  const to = from + LIMIT - 1

  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  const { data, error } = await supabase
    .from("businesses")
    .select(
      `
      id,
      name,
      slug,
      description,
      address,
      city,
      state,
      zip,
      parish,
      phone,
      website,
      logo_url,
      banner_url,
      latitude,
      longitude,
      updated_at,
      business_categories!businesses_category_id_fkey (
        id,
        name,
        slug,
        bucket
      ),
      business_subcategories (
        subcategories!business_subcategories_subcategory_id_fkey (
          id,
          name,
          slug
        )
      ),
      business_hours (
        day_of_week,
        open_time,
        close_time,
        is_closed
      )
    `
    )
    .eq("status", "approved")
    .gt("updated_at", lastSync)
    .order("updated_at", { ascending: true })
    .range(from, to)

  if (error) {
    console.error("directory-sync DB error:", error.message);
    return new Response(
      JSON.stringify({ error: "Database error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }

  return new Response(JSON.stringify(data ?? []), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  })
})
