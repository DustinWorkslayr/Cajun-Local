# Cajun Local — Pricing, Subscriptions & Advertising Cheat Sheet

> Technical reference for the 8 new tables added to support monetization.
> Last updated: 2026-02-21

---

## 1. New Enums (6)

| Enum | Values | Purpose |
|---|---|---|
| `subscription_tier` | `free`, `basic`, `premium`, `enterprise` | Plan levels for businesses |
| `user_subscription_tier` | `free`, `plus`, `pro` | Plan levels for end users |
| `billing_interval` | `monthly`, `yearly` | Payment frequency |
| `subscription_status` | `active`, `past_due`, `canceled`, `trialing` | Subscription lifecycle state |
| `ad_placement` | `directory_top`, `category_banner`, `search_results`, `deal_spotlight`, `homepage_featured` | Where ads render |
| `ad_status` | `draft`, `pending_payment`, `active`, `paused`, `expired`, `rejected` | Ad lifecycle state |

---

## 2. New Tables (8)

### 2.1 `business_plans` — Available business subscription packages

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| name | text | No | — | e.g. "Basic", "Premium" |
| tier | `subscription_tier` | No | — | Enum |
| price_monthly | numeric | No | 0 | USD |
| price_yearly | numeric | No | 0 | USD |
| features | jsonb | Yes | `'{}'` | Feature flags: `{"max_deals": 5, "max_images": 20}` |
| max_locations | integer | No | 1 | How many locations the plan supports |
| stripe_price_id_monthly | text | Yes | NULL | Stripe Price ID for monthly billing |
| stripe_price_id_yearly | text | Yes | NULL | Stripe Price ID for yearly billing |
| stripe_product_id | text | Yes | NULL | Stripe Product ID for tier mapping |
| is_active | boolean | No | true | Soft-delete / visibility toggle |
| sort_order | integer | No | 0 | Display ordering |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**RLS**: Public SELECT. Admin-only ALL.

---

### 2.2 `business_subscriptions` — Active business subscription records

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| business_id | uuid | No | — | FK → `businesses(id)` ON DELETE CASCADE. **UNIQUE** |
| plan_id | uuid | No | — | FK → `business_plans(id)` |
| status | `subscription_status` | No | `'active'` | |
| billing_interval | `billing_interval` | No | `'monthly'` | |
| current_period_start | timestamptz | Yes | — | |
| current_period_end | timestamptz | Yes | — | |
| stripe_subscription_id | text | Yes | — | For Stripe integration |
| stripe_customer_id | text | Yes | — | For Stripe integration |
| canceled_at | timestamptz | Yes | — | |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**Constraint**: `UNIQUE (business_id)` — one subscription per business.

**RLS**: Own business managers OR admin can SELECT. Admin-only ALL (INSERT/UPDATE/DELETE).

**Indexes**: `idx_business_subscriptions_business_id`, `idx_business_subscriptions_status`

**Deal and punch-card enforcement:** The business’s active plan tier (from `business_plans.tier`) controls deal creation limits and allowed deal types (simple vs advanced) and whether punch-card programs can be created. See [Backend Cheat Sheet — Business subscription and deals](./backend-cheatsheet.md#business-subscription-and-deals) for tier rules, triggers, and downgrade behavior.

---

### 2.3 `user_plans` — Available user subscription packages

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| name | text | No | — | e.g. "Plus", "Pro" |
| tier | `user_subscription_tier` | No | — | Enum |
| price_monthly | numeric | No | 0 | USD |
| price_yearly | numeric | No | 0 | USD |
| features | jsonb | Yes | `'{}'` | e.g. `{"exclusive_deals": true}` |
| stripe_price_id_monthly | text | Yes | NULL | Stripe Price ID for monthly billing |
| stripe_price_id_yearly | text | Yes | NULL | Stripe Price ID for yearly billing |
| stripe_product_id | text | Yes | NULL | Stripe Product ID for tier mapping |
| is_active | boolean | No | true | |
| sort_order | integer | No | 0 | |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**RLS**: Public SELECT. Admin-only ALL.

---

### 2.4 `user_subscriptions` — Active user subscription records

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| user_id | uuid | No | — | **UNIQUE** — one sub per user |
| plan_id | uuid | No | — | FK → `user_plans(id)` |
| status | `subscription_status` | No | `'active'` | |
| billing_interval | `billing_interval` | No | `'monthly'` | |
| current_period_start | timestamptz | Yes | — | |
| current_period_end | timestamptz | Yes | — | |
| stripe_subscription_id | text | Yes | — | |
| stripe_customer_id | text | Yes | — | |
| canceled_at | timestamptz | Yes | — | |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**Constraint**: `UNIQUE (user_id)`

**RLS**: Own user OR admin can SELECT. Admin-only ALL.

**Indexes**: `idx_user_subscriptions_user_id`, `idx_user_subscriptions_status`

---

### 2.5 `ad_packages` — Available advertising products

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| name | text | No | — | e.g. "Homepage Spotlight - 7 Days" |
| placement | `ad_placement` | No | — | Where the ad appears |
| duration_days | integer | No | — | How long the ad runs |
| price | numeric | No | 0 | One-time USD price |
| max_impressions | integer | Yes | — | Nullable; for impression-capped packages |
| description | text | Yes | — | |
| stripe_price_id | text | Yes | NULL | Stripe Price ID (one-time payment) |
| is_active | boolean | No | true | |
| sort_order | integer | No | 0 | |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**RLS**: Public SELECT. Admin-only ALL.

---

### 2.6 `business_ads` — Purchased ad placements

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| business_id | uuid | No | — | FK → `businesses(id)` ON DELETE CASCADE |
| package_id | uuid | No | — | FK → `ad_packages(id)` |
| status | `ad_status` | No | `'draft'` | |
| start_date | timestamptz | Yes | — | |
| end_date | timestamptz | Yes | — | |
| headline | text | Yes | — | Custom ad text |
| image_url | text | Yes | — | Custom ad image |
| target_url | text | Yes | — | Click-through URL |
| impressions | integer | No | 0 | **Server-incremented only** |
| clicks | integer | No | 0 | **Server-incremented only** |
| stripe_payment_id | text | Yes | — | |
| approved_by | uuid | Yes | — | **Server-set only** |
| approved_at | timestamptz | Yes | — | **Server-set only** |
| created_at | timestamptz | No | `now()` | |
| updated_at | timestamptz | No | `now()` | Auto-updated by trigger |

**RLS**:
- SELECT: Own business managers OR admin
- INSERT: Business managers (status defaults to `'draft'`)
- ALL (UPDATE/DELETE): Admin only

**Protected fields** (never client-writable): `impressions`, `clicks`, `approved_by`, `approved_at`

**Indexes**: `idx_business_ads_business_id`, `idx_business_ads_status`, `idx_business_ads_package_id`

---

### 2.7 `ad_impressions_log` — Analytics trail for ad views

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| ad_id | uuid | No | — | FK → `business_ads(id)` ON DELETE CASCADE |
| viewer_id | uuid | Yes | — | Nullable (anonymous views) |
| ip_hash | text | Yes | — | For dedup without raw IPs |
| created_at | timestamptz | No | `now()` | |

**RLS**: Admin-only ALL. Writes via server-side function or edge function only.

**Index**: `idx_ad_impressions_log_ad_id`

---

### 2.8 `payment_history` — Unified payment log

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | No | `gen_random_uuid()` | PK |
| user_id | uuid | Yes | — | For user subscriptions |
| business_id | uuid | Yes | — | For business subs/ads |
| amount | numeric | No | — | |
| currency | text | No | `'usd'` | |
| payment_type | text | No | — | `'business_subscription'`, `'user_subscription'`, `'advertisement'` |
| reference_id | uuid | Yes | — | Points to subscription or ad record |
| stripe_payment_intent_id | text | Yes | — | |
| status | text | No | `'succeeded'` | `'succeeded'`, `'failed'`, `'refunded'` |
| created_at | timestamptz | No | `now()` | |

**RLS**: Own user/business manager can SELECT. Admin can SELECT all. Admin-only ALL (no client writes).

**Indexes**: `idx_payment_history_user_id`, `idx_payment_history_business_id`

---

## 3. Security Summary

### RLS Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `business_plans` | **public** | admin | admin | admin |
| `business_subscriptions` | own manager OR admin | admin | admin | admin |
| `user_plans` | **public** | admin | admin | admin |
| `user_subscriptions` | own OR admin | admin | admin | admin |
| `ad_packages` | **public** | admin | admin | admin |
| `business_ads` | own manager OR admin | manager | admin | admin |
| `ad_impressions_log` | admin | admin | admin | admin |
| `payment_history` | own OR admin | admin | admin | admin |

### Fields Never Writable from Client

| Table | Protected Fields | Enforced By |
|---|---|---|
| `business_ads` | `impressions`, `clicks`, `approved_by`, `approved_at` | No client UPDATE policy |
| `business_subscriptions` | all fields | Admin-only write; Stripe webhooks |
| `user_subscriptions` | all fields | Admin-only write; Stripe webhooks |
| `payment_history` | all fields | Admin-only write; server-side logic |
| `ad_impressions_log` | all fields | Admin-only write; edge function |

---

## 4. Subscription Lifecycle

```
trialing → active → past_due → canceled
                  ↘ canceled (voluntary)
```

- **trialing**: Optional trial period before billing starts
- **active**: Payment current, features enabled
- **past_due**: Payment failed, grace period (features may be limited)
- **canceled**: Subscription ended; `canceled_at` is set

Managed by: Stripe webhooks → admin edge function → UPDATE `business_subscriptions` / `user_subscriptions`

---

## 5. Ad Moderation Flow

```
draft → pending_payment → active → expired
                        ↘ paused (by admin or business)
          ↘ rejected (by admin)
```

1. **draft**: Business manager creates ad via INSERT
2. **pending_payment**: Business submits for payment
3. **active**: Payment confirmed + admin approved; `approved_by` and `approved_at` set server-side
4. **paused**: Temporarily hidden (admin can pause)
5. **expired**: `end_date` passed or `max_impressions` reached
6. **rejected**: Admin rejects content

---

## 6. Stripe Integration Touchpoints

| Field | Table | Purpose |
|---|---|---|
| `stripe_subscription_id` | `business_subscriptions`, `user_subscriptions` | Maps to Stripe Subscription object |
| `stripe_customer_id` | `business_subscriptions`, `user_subscriptions` | Maps to Stripe Customer object |
| `stripe_payment_id` | `business_ads` | Maps to Stripe PaymentIntent for ad purchase |
| `stripe_payment_intent_id` | `payment_history` | Maps to Stripe PaymentIntent for audit |
| `stripe_price_id_monthly` | `business_plans`, `user_plans` | Stripe Price ID for monthly billing |
| `stripe_price_id_yearly` | `business_plans`, `user_plans` | Stripe Price ID for yearly billing |
| `stripe_product_id` | `business_plans`, `user_plans` | Stripe Product ID for tier mapping |
| `stripe_price_id` | `ad_packages` | Stripe Price ID for one-time ad purchase |

All Stripe fields are nullable (populated when Stripe integration is active).

---

## 7. Integration with Existing Schema

These 8 tables bring the total from **27 → 35 tables**.

**Foreign key relationships to existing tables:**
- `business_subscriptions.business_id` → `businesses(id)`
- `business_ads.business_id` → `businesses(id)`

**RLS functions reused from existing schema:**
- `public.has_role(uuid, app_role)` — admin checks
- `public.is_business_manager(uuid, uuid)` — business ownership checks

**Trigger reused:**
- `public.update_updated_at_column()` — applied to 6 of the 8 new tables

**No existing columns modified. No existing tables altered.**

---

## 8. Indexes (10 new)

| Index | Table | Column(s) |
|---|---|---|
| `idx_business_subscriptions_business_id` | business_subscriptions | business_id |
| `idx_business_subscriptions_status` | business_subscriptions | status |
| `idx_user_subscriptions_user_id` | user_subscriptions | user_id |
| `idx_user_subscriptions_status` | user_subscriptions | status |
| `idx_business_ads_business_id` | business_ads | business_id |
| `idx_business_ads_status` | business_ads | status |
| `idx_business_ads_package_id` | business_ads | package_id |
| `idx_ad_impressions_log_ad_id` | ad_impressions_log | ad_id |
| `idx_payment_history_user_id` | payment_history | user_id |
| `idx_payment_history_business_id` | payment_history | business_id |
