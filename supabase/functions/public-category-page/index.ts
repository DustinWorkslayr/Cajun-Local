// Cajun Local — public-category-page Edge Function
// Input: categorySlug (category id). Returns category, subcategories (tabs), banners, initial listings.
// Auth: x-wp-key. Uses SUPABASE_SERVICE_ROLE_KEY. Only approved businesses.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, ensureWpKey, jsonResponse } from "../_shared/wp-auth.ts";

const LISTINGS_PAGE_SIZE = 24;

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
  const categorySlug = url.searchParams.get("categorySlug")?.trim();
  if (!categorySlug) {
    return jsonResponse(400, { error: "Missing categorySlug" }, origin);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    return jsonResponse(503, { error: "Service not configured" }, origin);
  }
  const client = createClient(supabaseUrl, serviceRoleKey);

  const { data: cat, error: catErr } = await client
    .from("business_categories")
    .select("id, name, icon")
    .eq("id", categorySlug)
    .maybeSingle();
  if (catErr || !cat) {
    return jsonResponse(404, { error: "Category not found" }, origin);
  }

  const [subRes, bannersRes, bizRes, tiersRes] = await Promise.all([
    client.from("subcategories").select("id, name").eq("category_id", categorySlug).order("name"),
    client.from("category_banners").select("id, image_url").eq("category_id", categorySlug).eq("status", "approved"),
    client
      .from("businesses")
      .select("id, name, tagline, logo_url, city, parish, category_id")
      .eq("category_id", categorySlug)
      .eq("status", "approved")
      .range(0, LISTINGS_PAGE_SIZE - 1)
      .order("name"),
    client.from("business_subscriptions").select("business_id, business_plans(tier)").eq("status", "active"),
  ]);

  const subcategories = (subRes.data ?? []).map((s: { id: string; name: string }) => ({ id: s.id, name: s.name }));
  const banners = (bannersRes.data ?? []).map((b: { id: string; image_url: string }) => ({ id: b.id, image_url: b.image_url }));

  const businesses = (bizRes.data ?? []) as { id: string; name: string; tagline: string | null; logo_url: string | null; city: string | null; parish: string | null; category_id: string }[];
  const tierMap = new Map<string, string>();
  for (const row of tiersRes.data ?? []) {
    const r = row as { business_id: string; business_plans?: { tier?: string } };
    if (r.business_id && r.business_plans?.tier) tierMap.set(r.business_id, r.business_plans.tier);
  }

  const businessIds = businesses.map((b) => b.id);
  let subByBiz: Map<string, { id: string; name: string }[]> = new Map();
  if (businessIds.length > 0) {
    const { data: bs } = await client.from("business_subcategories").select("business_id, subcategory_id").in("business_id", businessIds);
    const subIds = [...new Set((bs ?? []).map((r: { subcategory_id: string }) => r.subcategory_id))];
    const { data: subList } = subIds.length
      ? await client.from("subcategories").select("id, name").in("id", subIds)
      : { data: [] };
    const subNameMap = new Map((subList ?? []).map((s: { id: string; name: string }) => [s.id, s.name]));
    for (const row of bs ?? []) {
      const r = row as { business_id: string; subcategory_id: string };
      const list = subByBiz.get(r.business_id) ?? [];
      const name = subNameMap.get(r.subcategory_id);
      if (name) list.push({ id: r.subcategory_id, name });
      subByBiz.set(r.business_id, list);
    }
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

  return jsonResponse(200, {
    category: { id: cat.id, name: cat.name, icon: cat.icon ?? null },
    subcategories,
    banners,
    listings,
  }, origin);
});
