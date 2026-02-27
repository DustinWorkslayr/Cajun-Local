// Cajun Local — sync-business-subscription Edge Function
// Verifies RevenueCat entitlement (or trusted payload) and updates business_subscriptions for a business.
// Call with service role key so RLS allows write. In production, verify RevenueCat webhook signature
// or call RevenueCat API to confirm entitlement before applying.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ENTITLEMENT_TO_PLAN: Record<string, { plan_type: string; plan_id: string }> = {
  business_local_plus: { plan_type: "local_plus", plan_id: "basic" },
  business_partner: { plan_type: "partner", plan_id: "premium" },
};

function cors(origin: string | null): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": origin ?? "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(status: number, body: object, origin: string | null) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors(origin) },
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin") ?? null;

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors(origin) });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" }, origin);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "Unauthorized" }, origin);
  }
  const token = authHeader.slice(7).trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  if (!supabaseUrl || !serviceRoleKey || token !== serviceRoleKey) {
    return jsonResponse(403, { error: "Forbidden" }, origin);
  }

  let body: {
    business_id?: string;
    entitlement?: string;
    plan_type?: "free" | "local_plus" | "partner";
    revenuecat_product_id?: string;
    status?: string;
    current_period_end?: string;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body" }, origin);
  }

  const businessId = typeof body?.business_id === "string" ? body.business_id.trim() : null;
  if (!businessId) {
    return jsonResponse(400, { error: "business_id is required" }, origin);
  }

  // Resolve plan_type and plan_id from entitlement or explicit plan_type
  let plan_type: "free" | "local_plus" | "partner" = "free";
  let plan_id = "free";
  if (body.entitlement && ENTITLEMENT_TO_PLAN[body.entitlement]) {
    const mapped = ENTITLEMENT_TO_PLAN[body.entitlement];
    plan_type = mapped.plan_type as "local_plus" | "partner";
    plan_id = mapped.plan_id;
  } else if (body.plan_type && ["free", "local_plus", "partner"].includes(body.plan_type)) {
    plan_type = body.plan_type;
    plan_id =
      plan_type === "local_plus" ? "basic" : plan_type === "partner" ? "premium" : "free";
  }

  const status =
    typeof body?.status === "string" && ["active", "trialing", "canceled", "past_due"].includes(body.status)
      ? body.status
      : "active";
  const revenuecat_product_id =
    typeof body?.revenuecat_product_id === "string" ? body.revenuecat_product_id.trim() : null;
  let current_period_end: string | null = null;
  if (typeof body?.current_period_end === "string" && body.current_period_end.trim()) {
    const d = new Date(body.current_period_end.trim());
    if (!Number.isNaN(d.getTime())) current_period_end = d.toISOString();
  }

  const client = createClient(supabaseUrl, serviceRoleKey);

  // Ensure business exists
  const { data: business, error: bizErr } = await client
    .from("businesses")
    .select("id")
    .eq("id", businessId)
    .single();
  if (bizErr || !business) {
    return jsonResponse(404, { error: "Business not found" }, origin);
  }

  const updatedAt = new Date().toISOString();
  const row = {
    business_id: businessId,
    plan_id,
    plan_type,
    revenuecat_product_id: revenuecat_product_id ?? null,
    status,
    billing_interval: "monthly",
    current_period_end: current_period_end ?? null,
    updated_at: updatedAt,
  };

  const { data: sub, error: upsertErr } = await client
    .from("business_subscriptions")
    .upsert(row, { onConflict: "business_id" })
    .select("id, business_id, plan_type, plan_id, status, current_period_end, revenuecat_product_id")
    .single();

  if (upsertErr) {
    return jsonResponse(500, { error: "Failed to upsert subscription", details: upsertErr.message }, origin);
  }

  return jsonResponse(200, { ok: true, subscription: sub }, origin);
});
