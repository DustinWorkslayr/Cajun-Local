# Cajun Local — Ask Local AI Edge Function Cheat Sheet

> Technical reference for the `ask-local` Supabase Edge Function that powers AI-driven local business recommendations.
> Last updated: 2026-02-22

---

## 1. Overview

The `ask-local` edge function receives a natural language question, queries the database for all approved business data, sends it as context to OpenAI, and streams the AI response back via SSE.

**Access:** Only **paid user tiers** — **Local+** ($2.99/month, tier `plus`) and **Pro** (tier `pro`). The function checks `user_subscriptions` (status = active) joined to `user_plans` (tier in `plus`, `pro`). Free-tier or unauthenticated callers receive 403. The AI tool is included in Local+.

**No new tables or migrations.** This feature reads from existing tables only.

---

## 2. Edge Function

**File:** `supabase/functions/ask-local/index.ts`

**Config** (`supabase/config.toml`):
```toml
[functions.ask-local]
verify_jwt = true
```

**Auth:** Requires a signed-in user with a **paid user subscription** (Local+ / plus or Pro). Free-tier users receive `403` with `code: "subscription_required"`. The client must send `Authorization: Bearer <user_jwt>`. Local+ ($2.99) subscribers (tier `plus`) must be allowed access.

---

## 3. API Reference

### Endpoint

```
POST {SUPABASE_URL}/functions/v1/ask-local
```

### Request Headers

| Header | Value |
|---|---|
| `Content-Type` | `application/json` |
| `Authorization` | `Bearer {user_jwt}` — **required**. Signed-in user's JWT (from Supabase Auth). |

### Request Body

```json
{
  "question": "Best crawfish near me under $20?"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `question` | string | Yes | Non-empty natural language question |

### Response — Success (200)

**Content-Type:** `text/event-stream`

Streams OpenAI-compatible SSE chunks:

```
data: {"id":"...","choices":[{"delta":{"content":"token text"}}]}

data: {"id":"...","choices":[{"delta":{"content":" more tokens"}}]}

data: [DONE]
```

Each `data:` line contains a JSON object with `choices[0].delta.content` holding the next token(s).

### Error Responses

| Status | Body | Meaning |
|---|---|---|
| `400` | `{"error": "A question is required."}` | Missing or empty `question` field |
| `403` | `{"error": "Sign in required.", "code": "auth_required"}` | No or invalid `Authorization` header |
| `403` | `{"error": "Invalid or expired session...", "code": "auth_invalid"}` | JWT invalid or expired |
| `403` | `{"error": "Ask Local is available for Plus and Pro members...", "code": "subscription_required"}` | User is on free tier; paid subscription required |
| `429` | `{"error": "Too many requests. Please try again in a moment."}` | OpenAI rate limit hit |
| `402` | `{"error": "AI service credits exhausted. Please try again later."}` | OpenAI billing issue |
| `500` | `{"error": "..."}` | Server error (missing API key, DB error, etc.) |

---

## 4. Data Context — What Gets Queried

The function fetches data from **8 sources** to build the AI context. Main listing data uses the **anon** client (RLS applies). Promotion data uses the **service role** client so the function can see subscription tier and active ads.

| Table(s) | Filter | Fields Used | Client |
|---|---|---|---|
| `businesses` | `status = 'approved'` | name, description, city, parish, address, phone, website, email, state, zip, category_id | anon |
| `business_categories` | joined via businesses | name | anon |
| `business_hours` | matched by business_id | day_of_week, open_time, close_time, is_closed | anon |
| `menu_sections` + `menu_items` | matched by business_id | section name, item name, price, is_available | anon |
| `deals` | `status = 'approved'`, `is_active = true` | title, description, deal_type | anon |
| `reviews` | `status = 'approved'` | rating (averaged per business) | anon |
| `business_events` | `status = 'approved'`, `event_date >= now()` | title, description, event_date | anon |
| `business_subscriptions` + `business_plans` | `status = 'active'`, `tier` in (`premium`, `enterprise`) | business_id, tier (for “top tier”) | **service role** |
| `business_ads` | `status = 'active'`, `start_date <= now()`, `end_date >= now()` | business_id, placement (for “active advertiser”) | **service role** |

### Context Assembly

- **Featured / Top providers:** Before the full listing, a short block lists business names that are either top-tier (premium/enterprise subscription) or have an active ad, with optional labels (e.g. “Premium partner”, “Homepage featured”). The AI is instructed to prefer these when they match the question.
- **Ordering:** Businesses are sorted so **featured first** (top-tier or active ad), then by name. That reinforces preference without relying only on the prompt.
- **Per-business block:** Each business is formatted as below. When a business is featured, a line `- Featured: <label>` is included (e.g. “Premium partner”, “Homepage featured”).

```
### Business Name
- Featured: premium partner; Homepage featured
- Category: Food & Dining
- City: Lafayette, LA 70501
- Parish: Lafayette
- Address: 123 Main St
- Phone: (337) 555-1234
- Website: https://example.com
- About: Description text
- Avg Rating: 4.2/5
- Hours: Mon: 09:00-17:00, Tue: 09:00-17:00, ...
- Menu: Crawfish Boil ($18.99), Gumbo ($12.99), ...
- Active Deals: 10% Off Lunch - Valid weekdays only
- Upcoming Events: Crawfish Festival (03/15/2026)
```

**Menu items** are capped at 15 per business. **Events** are capped at 5 per business. If `SUPABASE_SERVICE_ROLE_KEY` is missing, the function still runs but no businesses are marked as featured.

---

## 5. AI Configuration

| Setting | Value |
|---|---|
| **Provider** | OpenAI |
| **Model** | `gpt-4o-mini` |
| **Streaming** | `stream: true` (SSE) |
| **Secret** | `OPENAI_API_KEY` (Supabase secret) |

### System Prompt

```
You are "Cajun Local Guide", a friendly AI assistant for a local business
directory in Louisiana. Answer questions using ONLY the business listings
provided below. Never invent or hallucinate businesses, menu items, prices,
or hours. If no listing matches the question, say so honestly and suggest
browsing the directory. Always include the business name, city, and phone
when recommending. Keep answers concise and conversational.
Listings marked as Featured or Premium/Enterprise partners are our top providers;
when they match the user's question, prefer them and mention that they are
featured or a top partner when appropriate.
```

The context includes `=== FEATURED / TOP PROVIDERS ===` (if any) then `=== LISTINGS ===` with the full business blocks.

---

## 6. Secrets Required

| Secret Name | Where to Get It | Notes |
|---|---|---|
| `OPENAI_API_KEY` | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | Must have billing enabled |

Pre-existing secrets used (no setup needed):
- `SUPABASE_URL` — auto-configured
- `SUPABASE_ANON_KEY` — auto-configured (main listing queries; RLS applies)
- `SUPABASE_SERVICE_ROLE_KEY` — auto-configured (used only for promotion queries: top-tier subscriptions and active ads; if missing, the function runs without featuring any businesses)

---

## 7. Frontend Integration Pattern

### SSE Streaming Example

```typescript
const SUPABASE_URL = "https://qfcaxmlstwlutoojzcuq.supabase.co";

async function askLocal(question: string, accessToken: string, onToken: (text: string) => void) {
  const resp = await fetch(`${SUPABASE_URL}/functions/v1/ask-local`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ question }),
  });

  if (!resp.ok) {
    const err = await resp.json();
    throw new Error(err.error || "Request failed");
  }

  const reader = resp.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    let newlineIdx: number;
    while ((newlineIdx = buffer.indexOf("\n")) !== -1) {
      let line = buffer.slice(0, newlineIdx);
      buffer = buffer.slice(newlineIdx + 1);

      if (line.endsWith("\r")) line = line.slice(0, -1);
      if (!line.startsWith("data: ")) continue;

      const jsonStr = line.slice(6).trim();
      if (jsonStr === "[DONE]") return;

      try {
        const parsed = JSON.parse(jsonStr);
        const content = parsed.choices?.[0]?.delta?.content;
        if (content) onToken(content);
      } catch {
        buffer = line + "\n" + buffer;
        break;
      }
    }
  }
}
```

### React Usage

```typescript
const [answer, setAnswer] = useState("");
const [loading, setLoading] = useState(false);

const handleAsk = async (question: string) => {
  const token = await supabase.auth.getSession().then(({ data }) => data.session?.access_token);
  if (!token) {
    // Show sign-in or upgrade prompt
    return;
  }
  setAnswer("");
  setLoading(true);
  try {
    await askLocal(question, token, (chunk) => {
      setAnswer((prev) => prev + chunk);
    });
  } catch (e) {
    console.error(e);
    // Show error toast
  } finally {
    setLoading(false);
  }
};
```

---

## 8. Scaling Notes

- Currently fetches **all** approved businesses on every request — works well for < ~100 businesses.
- For larger directories, add keyword pre-filtering (search question for category/city terms, only fetch matching rows).
- OpenAI context window: `gpt-4o-mini` supports 128k tokens — ample for hundreds of businesses.

---

## 9. File Map

| File | Purpose |
|---|---|
| `supabase/functions/ask-local/index.ts` | Edge function — queries DB, calls OpenAI, streams response |
| `supabase/config.toml` | Function config — `verify_jwt = false` |
| `docs/ask-local-cheatsheet.md` | This document |
