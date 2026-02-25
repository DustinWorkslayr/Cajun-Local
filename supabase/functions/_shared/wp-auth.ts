// Shared: WordPress Edge API auth and CORS. Only Edge Functions use service role; WP uses x-wp-key.

const WP_KEY_HEADER = "x-wp-key";

export function corsHeaders(origin: string | null): Record<string, string> {
  const allow = origin ?? "*";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, " + WP_KEY_HEADER,
  };
}

export function ensureWpKey(req: Request): { ok: boolean; status?: number; body?: string } {
  const expected = Deno.env.get("WP_PUBLIC_API_KEY");
  if (!expected?.trim()) {
    return { ok: false, status: 503, body: JSON.stringify({ error: "WP_PUBLIC_API_KEY not configured" }) };
  }
  const provided = req.headers.get(WP_KEY_HEADER);
  if (!provided || provided.trim() !== expected.trim()) {
    return { ok: false, status: 401, body: JSON.stringify({ error: "Invalid or missing x-wp-key" }) };
  }
  return { ok: true };
}

export function jsonResponse(status: number, body: unknown, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}
