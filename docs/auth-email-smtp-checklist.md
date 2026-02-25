# Auth Email (Signup & Forgot Password) — SMTP Checklist

Signup confirmation and password-reset emails are sent by **Supabase Auth** using your project’s **SMTP** settings. They are not sent by the app or by the `send-email` / `process-email-queue` Edge Functions.

A **500 “Error sending confirmation email”** (or similar for reset) means Supabase’s SMTP send failed. Use this checklist to fix it.

---

## 1. Where to configure

- **Supabase Dashboard** → your project → **Authentication** → **SMTP Settings** (or **Email** / **SMTP** in the Auth section).

---

## 2. What to verify

| Setting | What to check |
|--------|----------------|
| **Enable Custom SMTP** | Must be ON for your own provider. |
| **Sender email** | Must be an address your SMTP provider allows (e.g. verified single sender or domain in SendGrid). Example: `accounts@sitesnapps.com`. |
| **Sender name** | Optional; e.g. "Cajun Local". |
| **Host** | Exact host from your provider (e.g. `smtp.sendgrid.net`, `smtp.gmail.com`). |
| **Port** | Usually **587** (STARTTLS) or **465** (SSL). Avoid 25. |
| **Username** | Often your full email or the value the provider gives (e.g. SendGrid: `apikey`). |
| **Password** | API key or app password from the provider. No typos; no extra spaces. |

---

## 3. Common causes of 500 / “Error sending email”

1. **535 Authentication failed**  
   Wrong SMTP username or password. Double-check in the provider’s dashboard; use App Password for Gmail/Google; for SendGrid use the SMTP/API key and username `apikey`.

2. **Sender not allowed**  
   The “Sender email” in Supabase must be verified in your provider (e.g. SendGrid: Single Sender Verification or domain authentication).

3. **Wrong host or port**  
   Use the provider’s documented SMTP host and port (587 with STARTTLS is common).

4. **Provider blocking**  
   Rate limits, new-account restrictions, or IP blocks. Check provider logs/dashboard.

---

## 4. Redirect URLs (for the link in the email)

In **Authentication** → **URL Configuration** → **Redirect URLs**, add:

- `cajunlocal://auth/confirm/**` (signup confirmation)
- `cajunlocal://reset-password/**` (password reset)

Wrong redirects don’t usually cause the 500; they affect what happens when the user clicks the link.

---

## 5. Check the actual error

- **Supabase Dashboard** → **Logs** (or **Authentication** → **Logs**).  
- Look for the request that failed (e.g. `/signup` or password reset) and the error message (e.g. `535 Authentication failed`, `Connection refused`, `Sender not verified`).  
- That message tells you whether the problem is credentials, host/port, sender, or provider.

---

## 6. SendGrid-specific

- **Username:** `apikey` (literal).  
- **Password:** A SendGrid API key with **Mail Send** permission.  
- **Sender email:** Must be a verified Single Sender or from a verified domain.  
- **Host:** `smtp.sendgrid.net` | **Port:** `587`.

---

## Summary

| Item | Action |
|------|--------|
| 500 on signup / forgot password | Supabase Auth SMTP is failing. |
| Fix location | Dashboard → Authentication → SMTP Settings. |
| Most common fix | Correct SMTP username + password and verified sender email. |
| Get exact reason | Dashboard → Logs, find the failed auth request and its error. |
