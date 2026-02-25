// Cajun Local — process-email-queue Edge Function
// Reads pending rows from email_queue, sends each via SendGrid using email_templates, marks sent/failed.
// Invoke via cron (no auth) or by admin (Authorization: Bearer <jwt>). Uses SUPABASE_SERVICE_ROLE_KEY and SENDGRID_API_KEY.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SENDGRID_URL = "https://api.sendgrid.com/v3/mail/send";
const BATCH_SIZE = 50;

/** If Authorization header is present, verify the user is admin. Return true to proceed, false to deny. */
async function ensureAdminOrCron(req: Request, supabaseUrl: string, serviceRoleKey: string): Promise<{ ok: boolean; status?: number; body?: string }> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { ok: true }; // No JWT = cron, allow
  }
  const token = authHeader.slice(7).trim();
  if (!token) return { ok: true };

  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!anonKey) {
    return { ok: false, status: 503, body: JSON.stringify({ error: "SUPABASE_ANON_KEY not set" }) };
  }
  const authClient = createClient(supabaseUrl, anonKey);
  const { data: { user }, error: userError } = await authClient.auth.getUser(token);
  if (userError || !user) {
    return { ok: false, status: 403, body: JSON.stringify({ error: "Invalid or expired token" }) };
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: roleRow } = await supabase
    .from("user_roles")
    .select("role")
    .eq("user_id", user.id)
    .eq("role", "admin")
    .maybeSingle();
  if (!roleRow) {
    return { ok: false, status: 403, body: JSON.stringify({ error: "Admin role required" }) };
  }
  return { ok: true };
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
  const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
  const fromEmail = Deno.env.get("SENDGRID_FROM_EMAIL") ?? "";
  const fromName = Deno.env.get("SENDGRID_FROM_NAME") ?? "Cajun Local";
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!sendgridKey || !supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing SENDGRID_API_KEY or Supabase env" }),
      { status: 503, headers: { "Content-Type": "application/json" } }
    );
  }

  const authResult = await ensureAdminOrCron(req, supabaseUrl, serviceRoleKey);
  if (!authResult.ok) {
    return new Response(authResult.body ?? "Forbidden", {
      status: authResult.status ?? 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: rows, error: fetchError } = await supabase
    .from("email_queue")
    .select("id, template_name, to_email, variables")
    .eq("status", "pending")
    .order("created_at", { ascending: true })
    .limit(BATCH_SIZE);

  if (fetchError) {
    console.error("email_queue select error:", fetchError);
    return new Response(
      JSON.stringify({ error: "Failed to fetch queue" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  if (!rows?.length) {
    return new Response(
      JSON.stringify({ processed: 0, message: "No pending emails" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  const variables = rows as { id: string; template_name: string; to_email: string; variables: Record<string, string> }[];
  let sent = 0;
  let failed = 0;

  for (const row of variables) {
    const vars = (row.variables as Record<string, string>) ?? {};
    let subject = "";
    let html = "";

    const { data: templateRow, error: templateError } = await supabase
      .from("email_templates")
      .select("subject, body")
      .eq("name", row.template_name)
      .maybeSingle();

    if (templateError || !templateRow) {
      await supabase
        .from("email_queue")
        .update({
          status: "failed",
          sent_at: new Date().toISOString(),
          error_message: templateError?.message ?? `Template '${row.template_name}' not found`,
        })
        .eq("id", row.id);
      failed++;
      continue;
    }

    subject = substitute(templateRow.subject as string, vars);
    const bodyText = substitute(templateRow.body as string, vars);
    html = `<div style="font-family: sans-serif; line-height: 1.5;">${bodyText.split("\n").map((line) => escapeHtml(line)).join("<br>\n")}</div>`;

    const sendgridBody = {
      personalizations: [{ to: [{ email: row.to_email }] }],
      from: { email: fromEmail || "account@cajunlocal.com", name: fromName },
      subject,
      content: [{ type: "text/html", value: html }],
    };

    const sendgridRes = await fetch(SENDGRID_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(sendgridBody),
    });

    if (sendgridRes.ok) {
      await supabase
        .from("email_queue")
        .update({ status: "sent", sent_at: new Date().toISOString(), error_message: null })
        .eq("id", row.id);
      sent++;
    } else {
      const errText = await sendgridRes.text();
      await supabase
        .from("email_queue")
        .update({
          status: "failed",
          sent_at: new Date().toISOString(),
          error_message: errText.slice(0, 500),
        })
        .eq("id", row.id);
      failed++;
    }
  }

  return new Response(
    JSON.stringify({ processed: rows.length, sent, failed }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
