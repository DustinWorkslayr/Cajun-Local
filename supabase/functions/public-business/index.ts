// Cajun Local — public-business Edge Function
// Input: slug (business slug or id for backward compat). Returns public profile for WordPress.
// Auth: x-wp-key. Uses SUPABASE_SERVICE_ROLE_KEY. Only approved businesses.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, ensureWpKey, jsonResponse } from "../_shared/wp-auth.ts";

const DAY_ORDER = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

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
  const slug = url.searchParams.get("slug")?.trim();
  if (!slug) {
    return jsonResponse(400, { error: "Missing slug" }, origin);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    return jsonResponse(503, { error: "Service not configured" }, origin);
  }
  const client = createClient(supabaseUrl, serviceRoleKey);

  // Resolve by slug first, then by id for backward compatibility
  let { data: biz, error: bizErr } = await client
    .from("businesses")
    .select("id, name, description, category_id, is_claimable")
    .eq("slug", slug)
    .eq("status", "approved")
    .maybeSingle();
  if (bizErr) {
    return jsonResponse(500, { error: "Lookup failed" }, origin);
  }
  if (!biz) {
    const byId = await client
      .from("businesses")
      .select("id, name, description, category_id, is_claimable")
      .eq("id", slug)
      .eq("status", "approved")
      .maybeSingle();
    if (byId.error || !byId.data) {
      return jsonResponse(404, { error: "Business not found" }, origin);
    }
    biz = byId.data;
  }

  const [hoursRes, categoryRes, subRes, subTierRes] = await Promise.all([
    client.from("business_hours").select("day_of_week, open_time, close_time, is_closed").eq("business_id", biz.id).order("day_of_week"),
    client.from("business_categories").select("id, name").eq("id", biz.category_id).maybeSingle(),
    client.from("business_subcategories").select("subcategory_id").eq("business_id", biz.id),
    client.from("business_subscriptions").select("business_id, business_plans(tier)").eq("business_id", biz.id).eq("status", "active").maybeSingle(),
  ]);

  const hoursRows = (hoursRes.data ?? []) as { day_of_week: string; open_time: string | null; close_time: string | null; is_closed: boolean | null }[];
  const hoursMap = new Map(hoursRows.map((h) => [h.day_of_week, { open_time: h.open_time, close_time: h.close_time, is_closed: h.is_closed }]));
  const hours = DAY_ORDER.map((day) => {
    const row = hoursMap.get(day);
    return { day, open_time: row?.open_time ?? null, close_time: row?.close_time ?? null, is_closed: row?.is_closed ?? true };
  });

  let subcategoryNames: { id: string; name: string }[] = [];
  if (subRes.data?.length) {
    const subIds = (subRes.data as { subcategory_id: string }[]).map((r) => r.subcategory_id);
    const { data: subList } = await client.from("subcategories").select("id, name").in("id", subIds);
    subcategoryNames = (subList ?? []).map((s: { id: string; name: string }) => ({ id: s.id, name: s.name }));
  }

  const tier = (subTierRes.data as { business_plans?: { tier?: string } } | null)?.business_plans?.tier ?? null;
  const is_local_plus = tier != null && tier !== "free";
  const is_partner = tier?.toLowerCase() === "enterprise";
  const is_unclaimed = biz.is_claimable === true;

  return jsonResponse(200, {
    name: biz.name,
    description: biz.description ?? null,
    hours,
    category: categoryRes.data ? { id: (categoryRes.data as { id: string }).id, name: (categoryRes.data as { name: string }).name } : null,
    subcategories: subcategoryNames,
    is_local_plus,
    is_partner,
    is_unclaimed,
  }, origin);
});
