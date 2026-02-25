// Cajun Local — send-templated-email Edge Function
// Same behavior as send-email: loads template from email_templates, substitutes {{variables}}, sends via SendGrid.
// Body: { to: string, template: string, variables: Record<string, string> }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SENDGRID_URL = "https://api.sendgrid.com/v3/mail/send";

function corsHeaders(origin: string | null): Record<string, string> {
  const allow = origin ?? "*";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function substitute(template: string, variables: Record<string, string>): string {
  let out = template;
  for (const [key, value] of Object.entries(variables)) {
    out = out.replace(new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, "g"), value ?? "");
  }
  return out;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(req.headers.get("Origin")) });
  }

  const origin = req.headers.get("Origin");

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }
  const token = authHeader.slice(7).trim();
  if (!token) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey) {
    return new Response(
      JSON.stringify({ error: "Server configuration error" }),
      { status: 503, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }
  const authClient = createClient(supabaseUrl, anonKey);
  const { data: { user }, error: userError } = await authClient.auth.getUser(token);
  if (userError || !user?.id) {
    return new Response(
      JSON.stringify({ error: "Invalid or expired session" }),
      { status: 403, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
  const fromEmail = Deno.env.get("SENDGRID_FROM_EMAIL") ?? "";
  const fromName = Deno.env.get("SENDGRID_FROM_NAME") ?? "Cajun Local";

  if (!sendgridKey) {
    console.error("SENDGRID_API_KEY not set");
    return new Response(
      JSON.stringify({ error: "Email service not configured" }),
      { status: 503, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  let body: { to?: string; template?: string; variables?: Record<string, string> };
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const to = typeof body.to === "string" ? body.to.trim() : "";
  const templateName = typeof body.template === "string" ? body.template.trim() : "";
  const variables = body.variables && typeof body.variables === "object" ? body.variables as Record<string, string> : {};

  if (!to || !templateName) {
    return new Response(
      JSON.stringify({ error: "Missing 'to' or 'template'" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("SUPABASE_SERVICE_ROLE_KEY missing");
    return new Response(
      JSON.stringify({ error: "Server configuration error" }),
      { status: 503, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const supabase = createClient(supabaseUrl!, serviceRoleKey);
  const { data: row, error: fetchError } = await supabase
    .from("email_templates")
    .select("subject, body")
    .eq("name", templateName)
    .maybeSingle();

  if (fetchError) {
    console.error("email_templates fetch error:", fetchError);
    return new Response(
      JSON.stringify({ error: "Failed to load template" }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }
  if (!row) {
    return new Response(
      JSON.stringify({ error: "Template not found" }),
      { status: 404, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const subject = substitute(row.subject as string, variables);
  const bodyText = substitute(row.body as string, variables);
  const html = `<div style="font-family: sans-serif; line-height: 1.5;">${bodyText.split("\n").map((line) => escapeHtml(line)).join("<br>\n")}</div>`;

  const sendgridBody = {
    personalizations: [{ to: [{ email: to }] }],
    from: { email: fromEmail || "account@cajunlocal.com", name: fromName },
    subject,
    content: [{ type: "text/html", value: html }],
  };

  const sendgridRes = await fetch(SENDGRID_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${sendgridKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(sendgridBody),
  });

  if (!sendgridRes.ok) {
    const errText = await sendgridRes.text();
    console.error("SendGrid error:", sendgridRes.status, errText);
    return new Response(
      JSON.stringify({ error: "Failed to send email" }),
      { status: 502, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
    );
  }

  const messageId = sendgridRes.headers.get("X-Message-Id") ?? undefined;
  return new Response(
    JSON.stringify({ ok: true, id: messageId }),
    { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } }
  );
});
