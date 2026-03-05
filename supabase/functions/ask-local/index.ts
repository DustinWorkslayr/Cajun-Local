// Cajun Local — ask-local Edge Function
// Queries approved business data, promotes top-tier and active advertisers, streams OpenAI response.
// See docs/ask-local-cheatsheet.md
/// <reference path="../_shared/deno.d.ts" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MENU_ITEMS_CAP = 15;
const EVENTS_CAP = 5;
/** Max approved businesses to load for context (avoids huge payloads and IN lists). */
const BUSINESS_CAP = 500;
/** Max question length (chars). */
const QUESTION_MAX_LENGTH = 1000;
/** OpenAI request timeout (ms). */
const OPENAI_TIMEOUT_MS = 28000;
/** Rate limit: max requests per user per window. */
const RATE_LIMIT_REQUESTS = 20;
/** Rate limit window (ms). */
const RATE_LIMIT_WINDOW_MS = 60_000;

/** In-memory rate limit: userId -> { count, resetAt }. For multi-instance deploy, use a Supabase table instead. */
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(userId);
  if (!entry) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }
  if (now >= entry.resetAt) {
    entry.count = 1;
    entry.resetAt = now + RATE_LIMIT_WINDOW_MS;
    return true;
  }
  entry.count++;
  if (entry.count > RATE_LIMIT_REQUESTS) return false;
  return true;
}
function cleanupRateLimit(): void {
  const now = Date.now();
  for (const [k, v] of rateLimitMap.entries()) {
    if (now >= v.resetAt) rateLimitMap.delete(k);
  }
}

const DAY_NAMES: Record<string, string> = {
  monday: "Mon",
  tuesday: "Tue",
  wednesday: "Wed",
  thursday: "Thu",
  friday: "Fri",
  saturday: "Sat",
  sunday: "Sun",
};

const AD_PLACEMENT_LABELS: Record<string, string> = {
  directory_top: "Directory top",
  category_banner: "Category banner",
  search_results: "Search results",
  deal_spotlight: "Deal spotlight",
  homepage_featured: "Homepage featured",
};

type SubRow = { business_id: string; plan_id: string };
type PlanRow = { id: string; tier: string };
type BusinessRow = {
  id: string;
  name: string;
  description: string | null;
  city: string | null;
  state: string | null;
  parish: string | null;
  address: string | null;
  phone: string | null;
  website: string | null;
  email: string | null;
  zip: string | null;
  category_id: string;
};

type CategoryRow = { id: string; name: string };
type HoursRow = { business_id: string; day_of_week: string; open_time: string | null; close_time: string | null; is_closed: boolean | null };
type MenuSectionRow = { id: string; business_id: string; name: string; sort_order: number | null };
type MenuItemRow = { section_id: string; name: string; price: number | string | null; is_available: boolean | null };
type DealRow = { business_id: string; title: string; description: string | null; deal_type: string };
type ReviewRow = { business_id: string; rating: number };
type EventRow = { business_id: string; title: string; description: string | null; event_date: string };

function corsHeaders(origin: string | null): Record<string, string> {
  const allow = origin ?? "*";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(status: number, body: unknown, origin: string | null) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

async function getTopTierBusinessIds(supabaseUrl: string, serviceRoleKey: string): Promise<Map<string, string>> {
  const client = createClient(supabaseUrl, serviceRoleKey);
  const { data: subs, error: subErr } = await client
    .from("business_subscriptions")
    .select("business_id, plan_id")
    .eq("status", "active");
  if (subErr || !subs?.length) return new Map();

  const planIds = [...new Set((subs as SubRow[]).map((s) => s.plan_id))];
  const { data: plans, error: planErr } = await client
    .from("business_plans")
    .select("id, tier")
    .in("id", planIds)
    .in("tier", ["premium", "enterprise"]);
  if (planErr || !plans?.length) return new Map();

  const planList = plans as PlanRow[];
  const topTierPlanIds = new Set(planList.map((p) => p.id));
  const tierByPlan = Object.fromEntries(planList.map((p) => [p.id, p.tier]));
  const result = new Map<string, string>();
  for (const s of subs as SubRow[]) {
    if (topTierPlanIds.has(s.plan_id)) result.set(s.business_id, tierByPlan[s.plan_id] ?? "premium");
  }
  return result;
}

async function getActiveAdBusinesses(supabaseUrl: string, serviceRoleKey: string): Promise<Map<string, string[]>> {
  const client = createClient(supabaseUrl, serviceRoleKey);
  const now = new Date().toISOString();
  const { data: ads, error } = await client
    .from("business_ads")
    .select("business_id, placement")
    .eq("status", "active")
    .lte("start_date", now)
    .gte("end_date", now);
  if (error || !ads?.length) return new Map();

  const byBusiness = new Map<string, string[]>();
  for (const ad of ads) {
    const label = AD_PLACEMENT_LABELS[ad.placement] ?? ad.placement;
    const list = byBusiness.get(ad.business_id) ?? [];
    if (!list.includes(label)) list.push(label);
    byBusiness.set(ad.business_id, list);
  }
  return byBusiness;
}

/** Returns true if the user has an active Cajun+ subscription. Uses service role. */
async function userHasCajunPlus(supabaseUrl: string, serviceRoleKey: string, userId: string): Promise<boolean> {
  const client = createClient(supabaseUrl, serviceRoleKey);
  const { data: sub, error } = await client
    .from("user_subscriptions")
    .select("plan_id")
    .eq("user_id", userId)
    .eq("status", "active")
    .eq("plan_id", "cajun_plus")
    .maybeSingle();
  if (error || !sub) return false;
  return true;
}

serve(async (req) => {
  const origin = req.headers.get("Origin") ?? "*";

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed." }, origin);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse(403, {
      error: "Sign in required.",
      code: "auth_required",
    }, origin);
  }
  const token = authHeader.slice(7).trim();
  if (!token) {
    return jsonResponse(403, { error: "Sign in required.", code: "auth_required" }, origin);
  }

  let body: { question?: string; preferred_parish_ids?: string[] };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body." }, origin);
  }

  const question = typeof body?.question === "string" ? body.question.trim() : "";
  if (!question) {
    return jsonResponse(400, { error: "A question is required." }, origin);
  }
  if (question.length > QUESTION_MAX_LENGTH) {
    return jsonResponse(400, { error: `Question must be ${QUESTION_MAX_LENGTH} characters or less.` }, origin);
  }

  const preferredParishIds =
    Array.isArray(body?.preferred_parish_ids) && body.preferred_parish_ids.length > 0
      ? new Set(body.preferred_parish_ids.map((id) => String(id).trim()).filter(Boolean))
      : null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openaiKey = Deno.env.get("OPENAI_API_KEY");

  if (!supabaseUrl || !anonKey || !openaiKey) {
    return jsonResponse(500, { error: "Server configuration error (missing env)." }, origin);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser(token);
  if (userError || !user?.id) {
    return jsonResponse(403, { error: "Invalid or expired session. Please sign in again.", code: "auth_invalid" }, origin);
  }

  if (!serviceRoleKey) {
    return jsonResponse(500, { error: "Server configuration error (subscription check unavailable)." }, origin);
  }
  const hasCajunPlus = await userHasCajunPlus(supabaseUrl, serviceRoleKey, user.id);
  if (!hasCajunPlus) {
    return jsonResponse(403, {
      error: "Ask Local is included with Cajun+ Membership. Upgrade to use this feature.",
      code: "subscription_required",
    }, origin);
  }

  cleanupRateLimit();
  if (!checkRateLimit(user.id)) {
    return jsonResponse(429, { error: "Too many requests. Please try again in a minute." }, origin);
  }

  const anonClient = createClient(supabaseUrl, anonKey);

  // Promotion data (service role) — optional; continue without if key missing
  let topTier = new Map<string, string>();
  let activeAds = new Map<string, string[]>();
  if (serviceRoleKey) {
    try {
      [topTier, activeAds] = await Promise.all([
        getTopTierBusinessIds(supabaseUrl, serviceRoleKey),
        getActiveAdBusinesses(supabaseUrl, serviceRoleKey),
      ]);
    } catch (e) {
      console.error("ask-local promotion data error:", e);
      // proceed without promotion data
    }
  }

  const featuredSet = new Set<string>([...topTier.keys(), ...activeAds.keys()]);
  const getFeaturedLabel = (businessId: string): string | null => {
    const tier = topTier.get(businessId);
    const placements = activeAds.get(businessId);
    const parts: string[] = [];
    if (tier) parts.push(`${tier} partner`);
    if (placements?.length) parts.push(placements.join(", "));
    return parts.length ? parts.join("; ") : null;
  };

  // Approved businesses with category and parish (capped for scale)
  const { data: businesses, error: bizErr } = await anonClient
    .from("businesses")
    .select("id, name, description, city, state, parish, address, phone, website, email, zip, category_id")
    .eq("status", "approved")
    .limit(BUSINESS_CAP);
  if (bizErr) {
    return jsonResponse(500, { error: "Failed to load businesses." }, origin);
  }
  let bizList = (businesses ?? []) as BusinessRow[];

  // Filter by user's preferred parishes when provided (include business if primary parish or any service-area parish matches)
  if (preferredParishIds && preferredParishIds.size > 0) {
    let businessParishIds: Map<string, Set<string>> = new Map();
    const bizIds = bizList.map((b) => b.id);
    const CHUNK = 200;
    try {
      for (let i = 0; i < bizIds.length; i += CHUNK) {
        const chunk = bizIds.slice(i, i + CHUNK);
        const { data: bpRows } = await anonClient
          .from("business_parishes")
          .select("business_id, parish_id")
          .in("business_id", chunk);
        for (const row of bpRows ?? []) {
          const r = row as { business_id: string; parish_id: string };
          const set = businessParishIds.get(r.business_id) ?? new Set();
          set.add(r.parish_id);
          businessParishIds.set(r.business_id, set);
        }
      }
    } catch (e) {
      console.error("ask-local business_parishes error:", e);
    }
    bizList = bizList.filter((b) => {
      const primary = b.parish?.trim();
      if (primary && preferredParishIds.has(primary)) return true;
      const extra = businessParishIds.get(b.id);
      if (extra) for (const pid of extra) if (preferredParishIds.has(pid)) return true;
      return false;
    });
  }

  if (bizList.length === 0) {
    const msg = preferredParishIds
      ? "No listings in your selected areas yet. Try other parishes or browse the directory."
      : "No approved listings yet. Try again later.";
    const ssePayload = JSON.stringify({ choices: [{ delta: { content: msg } }] });
    const sseBody = `data: ${ssePayload}\n\ndata: [DONE]\n\n`;
    return new Response(sseBody, {
      status: 200,
      headers: { "Content-Type": "text/event-stream", ...corsHeaders(origin) },
    });
  }

  const categoryIds = [...new Set(bizList.map((b) => b.category_id))];
  const { data: categories } = await anonClient.from("business_categories").select("id, name").in("id", categoryIds);
  const categoryMap = new Map<string, string>();
  for (const c of (categories ?? []) as CategoryRow[]) categoryMap.set(c.id, c.name);

  // business_hours, menu, deals, reviews, events per business (chunk to avoid huge IN lists)
  const businessIds = bizList.map((b) => b.id);
  const BATCH_SIZE = 200;
  const chunked = <T>(fn: (ids: string[]) => Promise<{ data: T[] | null }>): Promise<T[]> =>
    Promise.all(
      Array.from({ length: Math.ceil(businessIds.length / BATCH_SIZE) }, (_, i) =>
        fn(businessIds.slice(i * BATCH_SIZE, (i + 1) * BATCH_SIZE))
      )
    ).then((ress) => ress.flatMap((r) => (r.data ?? []) as T[]));

  const [hoursData, sectionsData, dealsData, reviewsData, eventsData] = await Promise.all([
    chunked<HoursRow>((ids) => anonClient.from("business_hours").select("business_id, day_of_week, open_time, close_time, is_closed").in("business_id", ids)),
    chunked<MenuSectionRow>((ids) => anonClient.from("menu_sections").select("id, business_id, name, sort_order").in("business_id", ids)),
    chunked<DealRow>((ids) => anonClient.from("deals").select("business_id, title, description, deal_type").eq("status", "approved").eq("is_active", true).in("business_id", ids)),
    chunked<ReviewRow>((ids) => anonClient.from("reviews").select("business_id, rating").eq("status", "approved").in("business_id", ids)),
    chunked<EventRow>((ids) => anonClient.from("business_events").select("business_id, title, description, event_date").eq("status", "approved").gte("event_date", new Date().toISOString()).in("business_id", ids)),
  ]);
  const hoursRes = { data: hoursData };
  const sectionsRes = { data: sectionsData };
  const dealsRes = { data: dealsData };
  const reviewsRes = { data: reviewsData };
  const eventsRes = { data: eventsData };

  const hoursByBiz = new Map<string, HoursRow[]>();
  for (const h of (hoursRes.data ?? []) as HoursRow[]) {
    const list = hoursByBiz.get(h.business_id) ?? [];
    list.push(h);
    hoursByBiz.set(h.business_id, list);
  }

  const sectionsByBiz = new Map<string, MenuSectionRow[]>();
  for (const s of (sectionsRes.data ?? []) as MenuSectionRow[]) {
    const list = sectionsByBiz.get(s.business_id) ?? [];
    list.push(s);
    sectionsByBiz.set(s.business_id, list);
  }
  const sectionIds = (sectionsRes.data ?? []).map((s: { id: string }) => s.id);
  const { data: menuItems } = await anonClient.from("menu_items").select("section_id, name, price, is_available").in("section_id", sectionIds);
  const itemsBySection = new Map<string, MenuItemRow[]>();
  for (const m of (menuItems ?? []) as MenuItemRow[]) {
    const list = itemsBySection.get(m.section_id) ?? [];
    list.push(m);
    itemsBySection.set(m.section_id, list);
  }

  const dealsByBiz = new Map<string, DealRow[]>();
  for (const d of (dealsRes.data ?? []) as DealRow[]) {
    const list = dealsByBiz.get(d.business_id) ?? [];
    list.push(d);
    dealsByBiz.set(d.business_id, list);
  }

  const reviewRatingsByBiz = new Map<string, number[]>();
  for (const r of (reviewsRes.data ?? []) as ReviewRow[]) {
    const list = reviewRatingsByBiz.get(r.business_id) ?? [];
    list.push(r.rating);
    reviewRatingsByBiz.set(r.business_id, list);
  }
  const reviewAvgByBiz = new Map<string, number>();
  for (const [bid, ratings] of reviewRatingsByBiz) {
    const avg = ratings.reduce((a, b) => a + b, 0) / ratings.length;
    reviewAvgByBiz.set(bid, Math.round(avg * 10) / 10);
  }

  const eventsByBiz = new Map<string, EventRow[]>();
  for (const e of (eventsRes.data ?? []) as EventRow[]) {
    const list = eventsByBiz.get(e.business_id) ?? [];
    list.push(e);
    eventsByBiz.set(e.business_id, list);
  }

  const formatHours = (rows: HoursRow[]): string => {
    const sorted = [...rows].sort((a, b) => (a.day_of_week > b.day_of_week ? 1 : -1));
    return sorted
      .map((r) => {
        const day = DAY_NAMES[r.day_of_week] ?? r.day_of_week;
        if (r.is_closed) return `${day}: closed`;
        return `${day}: ${r.open_time ?? "?"}-${r.close_time ?? "?"}`;
      })
      .join(", ");
  };

  const formatMenu = (businessId: string): string => {
    const sections = sectionsByBiz.get(businessId) ?? [];
    const sorted = [...sections].sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0));
    const parts: string[] = [];
    let count = 0;
    for (const sec of sorted) {
      const items = (itemsBySection.get(sec.id) ?? []).filter((i) => i.is_available !== false);
      for (const item of items) {
        if (count >= MENU_ITEMS_CAP) break;
        const price = item.price != null ? ` ($${Number(item.price).toFixed(2)})` : "";
        parts.push(`${item.name}${price}`);
        count++;
      }
      if (count >= MENU_ITEMS_CAP) break;
    }
    return parts.join(", ") || "—";
  };

  const formatDeals = (businessId: string): string => {
    const list = dealsByBiz.get(businessId) ?? [];
    return list.map((d) => d.title + (d.description ? ` — ${d.description}` : "")).join("; ") || "—";
  };

  const formatEvents = (businessId: string): string => {
    const list = (eventsByBiz.get(businessId) ?? []).slice(0, EVENTS_CAP);
    return list
      .map((e) => {
        const d = e.event_date.slice(0, 10);
        return `${e.title} (${d})` + (e.description ? ` — ${e.description}` : "");
      })
      .join("; ") || "—";
  };

  const buildBlock = (b: BusinessRow): string => {
    const lines: string[] = [];
    lines.push(`### ${b.name}`);
    const featuredLabel = getFeaturedLabel(b.id);
    if (featuredLabel) lines.push(`- Featured: ${featuredLabel}`);
    lines.push(`- Category: ${categoryMap.get(b.category_id) ?? "—"}`);
    lines.push(`- City: ${b.city ?? "—"} ${b.state ?? ""} ${b.zip ?? ""}`.trim());
    lines.push(`- Address: ${b.address ?? "—"}`);
    lines.push(`- Phone: ${b.phone ?? "—"}`);
    lines.push(`- Website: ${b.website ?? "—"}`);
    if (b.email) lines.push(`- Email: ${b.email}`);
    if (b.description) lines.push(`- About: ${b.description}`);
    const avg = reviewAvgByBiz.get(b.id);
    lines.push(`- Avg Rating: ${avg != null ? `${avg}/5` : "—"}`);
    lines.push(`- Hours: ${formatHours(hoursByBiz.get(b.id) ?? [])}`);
    lines.push(`- Menu: ${formatMenu(b.id)}`);
    lines.push(`- Active Deals: ${formatDeals(b.id)}`);
    lines.push(`- Upcoming Events: ${formatEvents(b.id)}`);
    return lines.join("\n");
  };

  // Sort: featured first (randomly ordered among themselves), then rest by name
  const featured = bizList.filter((b) => featuredSet.has(b.id));
  const rest = bizList.filter((b) => !featuredSet.has(b.id));
  const shuffle = <T>(arr: T[]): T[] => {
    const out = [...arr];
    for (let i = out.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
  };
  const sortedBusinesses = [...shuffle(featured), ...rest.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""))];

  const featuredNames: string[] = [];
  for (const b of sortedBusinesses) {
    if (!featuredSet.has(b.id)) break;
    const label = getFeaturedLabel(b.id);
    featuredNames.push(`${b.name}${label ? ` (${label})` : ""}`);
  }

  const featuredSection =
    featuredNames.length > 0
      ? `=== FEATURED / TOP PROVIDERS (prioritize these when they match) ===\n${featuredNames.join("\n")}\n\n`
      : "";

  const listingsBlock = sortedBusinesses.map((b) => buildBlock(b)).join("\n\n");
  const fullContext = `${featuredSection}=== LISTINGS ===\n\n${listingsBlock}`;

  const systemPrompt = `You are "Cajun Local Guide", a friendly AI assistant for a local business
directory in Louisiana. Answer questions using ONLY the business listings
provided below. Never invent or hallucinate businesses, menu items, prices,
or hours. If no listing matches the question, say so honestly and suggest
browsing the directory. Always include the business name, city, and phone
when recommending. Keep answers concise and conversational.
Listings marked as Featured or Premium/Enterprise partners are our top providers;
when they match the user's question, prefer them and mention that they are
featured or a top partner when appropriate.

IMPORTANT: At the very end of your reply, add exactly one line listing the business IDs you recommended, so the app can show them as cards. Use this exact format (comma-separated IDs, no spaces): [LISTINGS:id1,id2,id3]
Only include IDs from the LISTINGS data above. If you recommended no specific businesses, omit the line or use [LISTINGS:].`;

  const openaiBody = {
    model: "gpt-4o-mini",
    stream: true,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: `${fullContext}\n\n---\nUser question: ${question}` },
    ],
  };

  try {
    const ac = new AbortController();
    const timeoutId = setTimeout(() => ac.abort(), OPENAI_TIMEOUT_MS);
    const openaiRes = await fetch(OPENAI_URL, {
      method: "POST",
      signal: ac.signal,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openaiKey}`,
      },
      body: JSON.stringify(openaiBody),
    });
    clearTimeout(timeoutId);

    if (openaiRes.status === 429) {
      return jsonResponse(429, { error: "Too many requests. Please try again in a moment." }, origin);
    }
    if (openaiRes.status === 402) {
      return jsonResponse(402, { error: "AI service credits exhausted. Please try again later." }, origin);
    }
    if (!openaiRes.ok) {
      const errText = await openaiRes.text();
      console.error("OpenAI error:", openaiRes.status, errText.slice(0, 500));
      return jsonResponse(500, { error: "AI request failed. Please try again later." }, origin);
    }

    const stream = openaiRes.body;
    if (!stream) {
      return jsonResponse(500, { error: "No response stream." }, origin);
    }

    return new Response(stream, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        ...corsHeaders(origin),
      },
    });
  } catch (e) {
    const isAbort = e instanceof Error && e.name === "AbortError";
    console.error("Ask-local error:", isAbort ? "timeout" : (e instanceof Error ? e.message : String(e)));
    if (isAbort) {
      return jsonResponse(503, { error: "Request timed out. Please try again." }, origin);
    }
    return jsonResponse(500, { error: "Something went wrong. Please try again." }, origin);
  }
});
