# Cajun Local — WordPress Edge API

Public Edge Functions for WordPress to consume. **WordPress must never use the Supabase service role key.** Only these Edge Functions use the service role server-side; WordPress calls the function URLs with a shared secret header.

---

## Base URL and auth

- **Base URL:** `https://<your-project-ref>.supabase.co/functions/v1`
- **Required header:** `x-wp-key` must match the secret stored in Supabase as `WP_PUBLIC_API_KEY` (Edge Function secret).
- **Missing or invalid key:** `401` with body `{ "error": "Invalid or missing x-wp-key" }`.

Set the secret in Supabase Dashboard → Project Settings → Edge Functions → Secrets, or via CLI:

```bash
supabase secrets set WP_PUBLIC_API_KEY=your-shared-secret
```

---

## Endpoints

### 1. Public menu

**URL:** `GET /functions/v1/public-menu`

Returns buckets **Eat**, **Shop**, **Explore**, **Hire** with categories and subcategories for nav/menu.

**Example request (WordPress / cURL):**

```bash
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-menu"
```

**Response shape (200):**

```json
{
  "buckets": {
    "Eat": [
      { "id": "uuid", "name": "Restaurants", "icon": "restaurant", "subcategories": [{ "id": "uuid", "name": "Cajun" }, ...] }
    ],
    "Shop": [...],
    "Explore": [...],
    "Hire": []
  }
}
```

---

### 2. Public business

**URL:** `GET /functions/v1/public-business?slug=<id-or-slug>`

Returns one approved business by **slug**. Until a `slug` column exists on `businesses`, pass the business **id** (UUID) as `slug`.

**Example request:**

```bash
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-business?slug=33333333-3333-3333-3333-333333333301"
```

**Response shape (200):**

```json
{
  "name": "Bayou Bites",
  "description": "Family-owned since 1982...",
  "hours": [
    { "day": "monday", "open_time": "11:00", "close_time": "21:00", "is_closed": false },
    ...
  ],
  "category": { "id": "uuid", "name": "Restaurants" },
  "subcategories": [{ "id": "uuid", "name": "Cajun" }, ...],
  "is_local_plus": false,
  "is_partner": false,
  "is_unclaimed": true
}
```

**404** if not found or not approved.

---

### 3. Public category page

**URL:** `GET /functions/v1/public-category-page?categorySlug=<category-id>`

Returns category info, subcategories (for tabs), approved banners, and initial listing cards. Use category **id** as `categorySlug` (no slug column on categories yet).

**Example request:**

```bash
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-category-page?categorySlug=11111111-1111-1111-1111-111111111101"
```

**Response shape (200):**

```json
{
  "category": { "id": "uuid", "name": "Restaurants", "icon": "restaurant" },
  "subcategories": [{ "id": "uuid", "name": "Cajun" }, ...],
  "banners": [{ "id": "uuid", "image_url": "https://..." }, ...],
  "listings": [
    {
      "id": "uuid",
      "name": "Bayou Bites",
      "tagline": "Authentic gumbo & po'boys",
      "logo_url": "https://...",
      "city": "Lafayette",
      "parish": "lafayette",
      "subcategories": [{ "id": "uuid", "name": "Cajun" }],
      "is_local_plus": false,
      "is_partner": false
    }
  ]
}
```

---

### 4. Public search

**URL:** `GET /functions/v1/public-search?q=...&categorySlug=...&subcategorySlug=...&parish=...&flags=...&limit=...&offset=...`

All query parameters are optional. Returns listing cards only.

| Parameter         | Description |
|-------------------|-------------|
| `q`               | Text search (name, tagline, description). |
| `categorySlug`    | Category id. |
| `subcategorySlug` | Subcategory id. |
| `parish`          | Parish id (e.g. `lafayette`, `st_martin`). |
| `flags`           | Comma-separated: `is_local_plus`, `is_partner` to filter by tier. |
| `limit`           | Page size (default 20, max 50). |
| `offset`          | Pagination offset. |

**Example requests:**

```bash
# Full-text search
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-search?q=gumbo"

# By category and parish
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-search?categorySlug=11111111-1111-1111-1111-111111111101&parish=lafayette"

# Local Plus only, page 2
curl -s -H "x-wp-key: YOUR_WP_PUBLIC_API_KEY" \
  "https://<project-ref>.supabase.co/functions/v1/public-search?flags=is_local_plus&limit=20&offset=20"
```

**Response shape (200):**

```json
{
  "listings": [
    {
      "id": "uuid",
      "name": "Bayou Bites",
      "tagline": "Authentic gumbo & po'boys",
      "logo_url": "https://...",
      "city": "Lafayette",
      "parish": "lafayette",
      "subcategories": [{ "id": "uuid", "name": "Cajun" }],
      "is_local_plus": false,
      "is_partner": false
    }
  ],
  "total": 42
}
```

---

## Caching suggestions (WordPress)

- **public-menu:** Cache for 5–15 minutes (or on deploy). Menu changes infrequently.
- **public-business:** Cache per `slug` (e.g. 5–10 min). Invalidate or short TTL when business profile is updated.
- **public-category-page:** Cache per `categorySlug` (e.g. 2–5 min). Invalidate when category banners or listings change.
- **public-search:** Prefer short TTL (1–2 min) or no cache for search; or cache keyed by full query string with a short TTL.

Use the `x-wp-key` header only in server-side PHP (or WP server-side requests). Never expose it to the browser.

---

## Summary

| Function              | Method | Key query/body      | Returns                          |
|-----------------------|--------|----------------------|----------------------------------|
| `public-menu`         | GET    | —                    | Buckets with categories/subcats  |
| `public-business`     | GET    | `slug`               | One business profile + hours     |
| `public-category-page`| GET    | `categorySlug`       | Category, subcats, banners, list |
| `public-search`       | GET    | `q`, category, parish, flags, limit, offset | Listing cards + total   |

All functions return **only approved businesses** and **minimal public data** (no email, internal notes, proof docs, or audit logs).
