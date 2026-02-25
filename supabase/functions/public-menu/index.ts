// Cajun Local — public-menu Edge Function
// Returns buckets Eat/Shop/Explore/Hire with categories and subcategories for WordPress.
// Auth: x-wp-key must match WP_PUBLIC_API_KEY. Uses SUPABASE_SERVICE_ROLE_KEY server-side only.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, ensureWpKey, jsonResponse } from "../_shared/wp-auth.ts";

const BUCKETS = ["Eat", "Shop", "Explore", "Hire"] as const;
// No bucket column in business_categories yet: map by sort_order (1=Eat, 2=Explore, 3=Shop, default=Explore)
function bucketForSortOrder(sortOrder: number | null): (typeof BUCKETS)[number] {
  const o = sortOrder ?? 0;
  if (o === 1) return "Eat";
  if (o === 2) return "Explore";
  if (o === 3) return "Shop";
  return "Explore";
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin") ?? null;
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }
  if (req.method !== "GET") {
    return jsonResponse(405, { error: "Method not allowed" }, origin);
  }
  const auth = ensureWpKey(req);
  if (!auth.ok) {
    return new Response(auth.body, { status: auth.status ?? 401, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    return jsonResponse(503, { error: "Service not configured" }, origin);
  }
  const client = createClient(supabaseUrl, serviceRoleKey);

  const { data: categories, error: catErr } = await client
    .from("business_categories")
    .select("id, name, icon, sort_order")
    .order("sort_order", { ascending: true });
  if (catErr) {
    return jsonResponse(500, { error: "Failed to load categories" }, origin);
  }

  const categoryIds = (categories ?? []).map((c: { id: string }) => c.id);
  const { data: subcategories, error: subErr } = await client
    .from("subcategories")
    .select("id, name, category_id")
    .in("category_id", categoryIds.length ? categoryIds : ["__none__"])
    .order("name", { ascending: true });
  if (subErr) {
    return jsonResponse(500, { error: "Failed to load subcategories" }, origin);
  }

  const subByCategory = new Map<string, { id: string; name: string }[]>();
  for (const s of subcategories ?? []) {
    const list = subByCategory.get(s.category_id) ?? [];
    list.push({ id: s.id, name: s.name });
    subByCategory.set(s.category_id, list);
  }

  const byBucket: Record<string, { id: string; name: string; icon: string | null; subcategories: { id: string; name: string }[] }[]> = {};
  for (const b of BUCKETS) byBucket[b] = [];
  for (const c of categories ?? []) {
    const bucket = bucketForSortOrder(c.sort_order);
    byBucket[bucket].push({
      id: c.id,
      name: c.name,
      icon: c.icon ?? null,
      subcategories: subByCategory.get(c.id) ?? [],
    });
  }

  return jsonResponse(200, { buckets: byBucket }, origin);
});
