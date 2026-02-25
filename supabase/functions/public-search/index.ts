// Cajun Local — public-search Edge Function
// Query params: q, categorySlug, subcategorySlug, parish, flags, limit, offset. Returns listing cards only.
// Auth: x-wp-key. Uses SUPABASE_SERVICE_ROLE_KEY. Only approved businesses.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, ensureWpKey, jsonResponse } from "../_shared/wp-auth.ts";

const MAX_LIMIT = 50;
const DEFAULT_LIMIT = 20;

function parseIntSafe(val: string | null, def: number, max: number): number {
  if (val == null || val.trim() === "") return def;
  const n = parseInt(val, 10);
  if (!Number.isFinite(n) || n < 0) return def;
  return Math.min(n, max);
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

  const url = new URL(req.url);
  const q = url.searchParams.get("q")?.trim() ?? "";
  const categorySlug = url.searchParams.get("categorySlug")?.trim() ?? null;
  const subcategorySlug = url.searchParams.get("subcategorySlug")?.trim() ?? null;
  const parish = url.searchParams.get("parish")?.trim() ?? null;
  const flagsParam = url.searchParams.get("flags")?.trim() ?? "";
  const flags = flagsParam ? new Set(flagsParam.split(",").map((f) => f.trim().toLowerCase()).filter(Boolean)) : new Set<string>();
  const limit = parseIntSafe(url.searchParams.get("limit"), DEFAULT_LIMIT, MAX_LIMIT);
  const offset = parseIntSafe(url.searchParams.get("offset"), 0, 10000);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    return jsonResponse(503, { error: "Service not configured" }, origin);
  }
  const client = createClient(supabaseUrl, serviceRoleKey);

  let query = client
    .from("businesses")
    .select("id, name, tagline, logo_url, city, parish, category_id", { count: "exact" })
    .eq("status", "approved");

  if (categorySlug) query = query.eq("category_id", categorySlug);
  if (parish) query = query.eq("parish", parish);
  if (q) {
    const escaped = q.replace(/\\/g, "\\\\").replace(/%/g, "\\%").replace(/'/g, "''").replace(/,/g, "");
    const pat = `%${escaped}%`;
    query = query.or(`name.ilike.${pat},tagline.ilike.${pat},description.ilike.${pat}`);
  }

  if (subcategorySlug) {
    const { data: bizIds } = await client.from("business_subcategories").select("business_id").eq("subcategory_id", subcategorySlug);
    const ids = (bizIds ?? []).map((r: { business_id: string }) => r.business_id);
    if (ids.length === 0) {
      return jsonResponse(200, { listings: [], total: 0 }, origin);
    }
    query = query.in("id", ids);
  }

  // Apply tier filters at query time so count is correct
  if (flags.has("is_partner") || flags.has("is_local_plus")) {
    const { data: subRows } = await client
      .from("business_subscriptions")
      .select("business_id, business_plans(tier)")
      .eq("status", "active");
    const partnerIds = new Set<string>();
    const localPlusIds = new Set<string>();
    for (const row of subRows ?? []) {
      const r = row as { business_id: string; business_plans?: { tier?: string } };
      const tier = r.business_plans?.tier?.toLowerCase();
      if (!tier || !r.business_id) continue;
      if (tier === "enterprise") partnerIds.add(r.business_id);
      if (tier !== "free") localPlusIds.add(r.business_id);
    }
    let tierFilterIds: string[] = [];
    if (flags.has("is_partner") && flags.has("is_local_plus")) {
      tierFilterIds = [...partnerIds].filter((id) => localPlusIds.has(id));
    } else if (flags.has("is_partner")) {
      tierFilterIds = [...partnerIds];
    } else {
      tierFilterIds = [...localPlusIds];
    }
    if (tierFilterIds.length === 0) {
      return jsonResponse(200, { listings: [], total: 0 }, origin);
    }
    query = query.in("id", tierFilterIds);
  }

  const { data: rows, error, count } = await query.range(offset, offset + limit - 1).order("name");
  if (error) {
    return jsonResponse(500, { error: "Search failed" }, origin);
  }

  const businesses = (rows ?? []) as { id: string; name: string; tagline: string | null; logo_url: string | null; city: string | null; parish: string | null; category_id: string }[];
  if (businesses.length === 0) {
    return jsonResponse(200, { listings: [], total: count ?? 0 }, origin);
  }

  const businessIds = businesses.map((b) => b.id);
  const [tiersRes, subRes] = await Promise.all([
    client.from("business_subscriptions").select("business_id, business_plans(tier)").in("business_id", businessIds).eq("status", "active"),
    client.from("business_subcategories").select("business_id, subcategory_id").in("business_id", businessIds),
  ]);

  const tierMap = new Map<string, string>();
  for (const row of tiersRes.data ?? []) {
    const r = row as { business_id: string; business_plans?: { tier?: string } };
    if (r.business_id && r.business_plans?.tier) tierMap.set(r.business_id, r.business_plans.tier);
  }
  const subIds = [...new Set((subRes.data ?? []).map((r: { subcategory_id: string }) => r.subcategory_id))];
  const { data: subList } = subIds.length ? await client.from("subcategories").select("id, name").in("id", subIds) : { data: [] };
  const subNameMap = new Map((subList ?? []).map((s: { id: string; name: string }) => [s.id, s.name]));
  const subByBiz = new Map<string, { id: string; name: string }[]>();
  for (const row of subRes.data ?? []) {
    const r = row as { business_id: string; subcategory_id: string };
    const list = subByBiz.get(r.business_id) ?? [];
    const name = subNameMap.get(r.subcategory_id);
    if (name) list.push({ id: r.subcategory_id, name });
    subByBiz.set(r.business_id, list);
  }

  const listings = businesses.map((b) => {
    const tier = tierMap.get(b.id);
    return {
      id: b.id,
      name: b.name,
      tagline: b.tagline ?? null,
      logo_url: b.logo_url ?? null,
      city: b.city ?? null,
      parish: b.parish ?? null,
      subcategories: subByBiz.get(b.id) ?? [],
      is_local_plus: tier != null && tier !== "free",
      is_partner: tier?.toLowerCase() === "enterprise",
    };
  });

  return jsonResponse(200, { listings, total: count ?? listings.length }, origin);
});
