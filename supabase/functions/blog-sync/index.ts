import { serve } from "https://deno.land/std/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {

  const secret = req.headers.get("x-sync-key")

  if (secret !== Deno.env.get("WP_SYNC_SECRET")) {
    return new Response("Unauthorized", { status: 401 })
  }

  const url = new URL(req.url)
  const lastSync = url.searchParams.get("last_sync") ?? "1970-01-01"

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  const { data, error } = await supabase
    .from("blog_posts")
    .select(`
      id,
      title,
      slug,
      content,
      excerpt,
      cover_image_url,
      published_at,
      updated_at
    `)
    .eq("status", "approved")
    .gt("updated_at", lastSync)
    .order("published_at", { ascending: false })

  if (error) {
    return new Response(JSON.stringify(error), { status: 500 })
  }

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" }
  })
})