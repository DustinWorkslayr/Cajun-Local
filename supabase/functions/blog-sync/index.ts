import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_LIMIT = 200;
const DEFAULT_LIMIT = 100;

function parseIntSafe(val: string | null, def: number, max: number): number {
  if (val == null || val.trim() === "") return def;
  const n = parseInt(val, 10);
  if (!Number.isFinite(n) || n < 0) return def;
  return Math.min(n, max);
}

serve(async (req) => {
  const secret = req.headers.get("x-sync-key");
  if (secret !== Deno.env.get("WP_SYNC_SECRET")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("blog-sync: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return new Response(JSON.stringify({ error: "Server configuration error" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(req.url);
  const lastSync = url.searchParams.get("last_sync") ?? "1970-01-01";
  const limit = parseIntSafe(url.searchParams.get("limit"), DEFAULT_LIMIT, MAX_LIMIT);
  const offset = parseIntSafe(url.searchParams.get("offset"), 0, 10000);

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data, error, count } = await supabase
    .from("blog_posts")
    .select("id, title, slug, content, excerpt, cover_image_url, parish_ids, published_at, updated_at", { count: "exact" })
    .eq("status", "approved")
    .gt("updated_at", lastSync)
    .order("published_at", { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    console.error("blog-sync DB error:", error.message);
    return new Response(JSON.stringify({ error: "Failed to fetch posts" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const total = count ?? (data?.length ?? 0);
  return new Response(
    JSON.stringify({ posts: data ?? [], total, hasMore: (data?.length ?? 0) === limit }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});