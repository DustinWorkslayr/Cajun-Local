# Cajun Local — Backend Architecture Cheat Sheet

> Technical reference. No UI. No marketing. Backend logic and security only.
> Last updated: 2026-02-21
>
> **See also:**
> - [Pricing, Subscriptions & Advertising Cheat Sheet](./pricing-and-ads-cheatsheet.md) — covers the 8 monetization tables.
> - [Messaging & FAQs Cheat Sheet](./messaging-faqs-cheatsheet.md) — covers conversations, messages, and business FAQs.
> - [Stripe Integration Cheat Sheet](./stripe-cheatsheet.md) — covers Stripe edge functions, checkout flows, and metadata conventions.

---

## 1. Database Overview (41 Tables — 27 core + 9 ads/monetization + 3 messaging/FAQs + 1 events + 1 RSVP)

**Schema alignment:** The live database may use different column names than the app expects. See [§1.1 Schema alignment (DB vs app)](#11-schema-alignment-db-vs-app) below.

### Core Business Tables

| Table | Purpose | Key Fields | Relationships |
|---|---|---|---|
| `businesses` | Primary listing entity | name, status, category_id, city, state, latitude/longitude (or lat/lng), cover_image_url (or logo_url, banner_url) | → business_categories, ← business_managers, ← deals, ← reviews |
| `business_categories` | Top-level classification | name (unique), icon, sort_order | ← businesses, ← subcategories, ← category_banners |
| `subcategories` | Second-level classification | name, category_id | → business_categories |
| `business_subcategories` | M:N join table | business_id, subcategory_id (unique pair) | → businesses, → subcategories |
| `business_hours` | Operating hours per day | business_id, day_of_week (unique pair), open/close_time, is_closed | → businesses |
| `business_images` | Gallery images with moderation | url, business_id, status, sort_order | → businesses |
| `business_links` | External URLs (social, website) | url, label, business_id, sort_order | → businesses |
| `menu_sections` | Menu category groupings | name, business_id, sort_order | → businesses, ← menu_items |
| `menu_items` | Individual menu entries | name, price, section_id, is_available | → menu_sections |

### User & Identity Tables

| Table | Purpose | Key Fields | Relationships |
|---|---|---|---|
| `profiles` | Public user info (mirrors auth.users) | user_id (unique), display_name, email, avatar_url | Created by `handle_new_user` trigger |
| `user_roles` | RBAC role assignments | user_id, role (enum: admin/business_owner/user) | Queried by `has_role()` |
| `business_managers` | Links users to businesses they manage | business_id, user_id (unique pair), role | → businesses |
| `business_claims` | Ownership claim requests | business_id, user_id, status, claim_details | → businesses |

### Deals & Loyalty Tables

| Table | Purpose | Key Fields | Relationships |
|---|---|---|---|
| `deals` | Business promotions with moderation | title, business_id, deal_type, status, start/end_date | → businesses |
| `user_deals` | Tracks claimed deals per user | user_id, deal_id (unique pair), claimed_at, used_at | → deals |
| `punch_card_programs` | Loyalty program definitions | business_id, punches_required, reward_description, is_active | → businesses |
| `user_punch_cards` | User enrollment in programs | user_id, program_id, current_punches, is_redeemed | → punch_card_programs |
| `punch_tokens` | One-time QR scan tokens | token (unique), user_punch_card_id, is_used, created_at | → user_punch_cards |
| `punch_history` | Audit trail of punches | user_punch_card_id, punched_by, punch_token | → user_punch_cards |

### Engagement Tables

| Table | Purpose | Key Fields | Relationships |
|---|---|---|---|
| `reviews` | User reviews with moderation | business_id, user_id, rating, status | → businesses |
| `favorites` | Bookmarked businesses | user_id, business_id (unique pair) | → businesses |
| `event_rsvps` | User RSVPs to business events | event_id, user_id (unique pair), status (going/interested/not_going) | → business_events |

### Content & Admin Tables

| Table | Purpose | Key Fields | Relationships |
|---|---|---|---|
| `blog_posts` | CMS content with moderation | slug (unique), title, content (or body), excerpt, cover_image_url, status, author_id | — |
| `category_banners` | Hero images per category | category_id, image_url, status | → business_categories |
| `notification_banners` | System-wide announcements | title, message, link, is_active, start/end_date | — |
| `notifications` | Per-user notifications | user_id, title, type, is_read | — |
| `email_templates` | Email content templates | name (unique), subject, body | — |
| `email_queue` | Queue for DB-triggered emails | template_name, to_email, variables (jsonb), status (pending/sent/failed), sent_at, error_message | Triggers enqueue; `process-email-queue` edge function sends |
| `audit_log` | Admin action logging | action, user_id, target_table, target_id, details | — |

### Email Template Placeholders

Templated emails use `{{variable_name}}` in `subject` and `body`. The send-templated-email Edge Function replaces each `{{key}}` with the value from the request's `variables` map. No app code enforces which variables a template uses; the list below is for authoring.

| Template name (example) | Suggested variables | When sent |
|---|---|---|
| `welcome_email` | `display_name`, `email` | After signup |
| `claim_approved` | `display_name`, `email`, `business_name` | Admin approves business claim |
| `claim_rejected` | `display_name`, `business_name` | Admin rejects claim |
| `deal_claimed` | `display_name`, `deal_title`, `business_name` | User claims a deal |
| `business_approved` | `display_name`, `email`, `business_name` | Admin approves business listing |
| `deal_approved` | `display_name`, `email`, `deal_title`, `business_name` | Admin approves deal |
| `review_approved` | `display_name`, `email`, `business_name` | Admin approves review |
| `image_approved` | `display_name`, `email`, `business_name` | Admin approves business image |

### 1.1 Schema alignment (DB vs app)

The following differences exist between the **live database** schema (as exported from Supabase) and what the **app code** expects. Align either the DB or the app so they match.

| Table | Live DB columns | App expects | Action |
|---|---|---|---|
| `blog_posts` | `content`, `excerpt`, `cover_image_url` | `body`, `cover_image_url` | Add a `body` column (and sync with `content`) or rename `content` → `body`; or change the app to use `content` and optionally `excerpt`. |
| `businesses` | `latitude`, `longitude`, `cover_image_url` | `lat`, `lng`, `logo_url`, `banner_url` | Add columns `lat`, `lng`, `logo_url`, `banner_url` (repo migration `20260221200000` adds logo_url/banner_url); or add `latitude`/`longitude` and map in app. Ensure only one set is used consistently. |

**Tables created only in repo migrations** (not in initial DB dump): `business_parishes`, `email_queue`. Ensure migrations `20260221000000_add_business_parishes.sql` and `20260221120000_email_queue_and_triggers.sql` have been applied.

**Extra table in live DB:** `ad_impressions_log` — documented in [Pricing & Ads Cheat Sheet](./pricing-and-ads-cheatsheet.md).

---

## 2. Security Model

### Roles

| Role | Description |
|---|---|
| `admin` | Full access to all tables. Can moderate, approve, delete. |
| `business_owner` | Assigned when claim approved. Manages own businesses via `business_managers`. |
| `user` | Default role. Can favorite, review, claim deals, enroll in punch cards. |

### Helper Functions (SECURITY DEFINER)

| Function | Purpose |
|---|---|
| `has_role(user_id, role)` | Checks `user_roles` table. Used in all admin RLS policies. |
| `is_business_manager(user_id, business_id)` | Checks `business_managers` table. Used in business-scoped RLS. |
| `validate_and_punch(token, punched_by)` | Server-side punch validation. Returns JSONB. |
| `redeem_punch_card(card_id, redeemed_by)` | Server-side reward redemption. Returns JSONB. |
| `get_favorites_count(business_id)` | Returns total count of favorites for a business. SECURITY DEFINER so anon/authenticated can call for display. Migration: `20260221160000_favorites_count_rpc.sql`. |
| `handle_new_user()` | Trigger function: creates profile + assigns `user` role on signup. |
| `update_updated_at_column()` | Trigger function: sets `updated_at = now()` on row update. |

### RLS Policy Summary

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `audit_log` | admin | admin | admin | admin |
| `blog_posts` | approved OR admin | admin | admin | admin |
| `business_categories` | **public** | admin | admin | admin |
| `business_claims` | own OR admin | own (user_id=uid) | admin | admin |
| `business_events` | approved OR admin OR manager | admin OR manager | admin OR manager | admin OR manager |
| `business_hours` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `business_images` | approved OR admin OR manager | admin OR manager | admin OR manager | admin OR manager |
| `business_links` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `business_managers` | admin OR manager | existing manager (not self) | admin | admin |
| `business_subcategories` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `businesses` | approved OR admin OR manager | own (created_by=uid) | admin OR manager | admin only |
| `category_banners` | approved OR admin | admin | admin | admin |
| `deals` | approved OR admin OR manager | admin OR manager | admin OR manager | admin OR manager |
| `email_templates` | admin | admin | admin | admin |
| `email_queue` | service role only (no client) | — | — | — |
| `favorites` | own | own (user_id=uid) | ❌ none | own |
| `menu_items` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `menu_sections` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `notification_banners` | active OR admin | admin | admin | admin |
| `notifications` | own | admin | own | admin |
| `profiles` | own OR admin | own (user_id=uid) | own OR admin | ❌ none |
| `punch_card_programs` | **public** | admin OR manager | admin OR manager | admin OR manager |
| `punch_history` | own card OR admin | admin | admin | admin |
| `punch_tokens` | own card | own card (via RLS) | admin | admin |
| `reviews` | approved OR own OR admin | own (user_id=uid) | own OR admin | own OR admin |
| `subcategories` | **public** | admin | admin | admin |
| `user_deals` | own OR admin | own (user_id=uid) | admin | admin |
| `user_punch_cards` | own OR admin | own (user_id=uid) | admin | admin |
| `event_rsvps` | own OR approved-event viewers | own (user_id=uid) | own | own OR admin |
| `user_roles` | own | admin | admin | admin |

### Fields Never Writable from Client

| Table | Protected Fields | Enforced By |
|---|---|---|
| `user_punch_cards` | `current_punches`, `is_redeemed`, `redeemed_at` | No UPDATE RLS policy for users; only `validate_and_punch()` and `redeem_punch_card()` modify |
| `punch_tokens` | `is_used`, `used_at` | No UPDATE RLS policy for users; only `validate_and_punch()` modifies |
| `businesses` | `status`, `approved_at`, `approved_by` | Only admin can change status |
| `deals` | `status`, `approved_at`, `approved_by` | Only admin can change status |
| `business_images` | `status`, `approved_at`, `approved_by` | Only admin can change status |
| `reviews` | `status`, `approved_at`, `approved_by` | Only admin can change status |
| `user_roles` | `role` | Only admin can INSERT/UPDATE/DELETE |

---

## 3. Status & Moderation Model

### Enums

| Enum | Values | Used By |
|---|---|---|
| `approval_status` | `pending`, `approved`, `rejected` | businesses, deals, reviews, blog_posts, business_images, category_banners, business_claims, business_events |
| `app_role` | `admin`, `business_owner`, `user` | user_roles |
| `deal_type` | `percentage`, `fixed`, `bogo`, `freebie`, `other`, `flash`, `member_only` (simple: first five; advanced: flash, member_only) | deals |
| `day_of_week` | `monday` through `sunday` | business_hours |
| `subscription_tier` | `free`, `basic`, `premium`, `enterprise` | business_plans |
| `user_subscription_tier` | `free`, `plus`, `pro` | user_plans |
| `billing_interval` | `monthly`, `yearly` | business_subscriptions, user_subscriptions |
| `subscription_status` | `active`, `past_due`, `canceled`, `trialing` | business_subscriptions, user_subscriptions |
| `ad_placement` | `directory_top`, `category_banner`, `search_results`, `deal_spotlight`, `homepage_featured` | ad_packages |
| `ad_status` | `draft`, `pending_payment`, `active`, `paused`, `expired`, `rejected` | business_ads |

### Approval Flows

| Entity | Default Status | Who Approves | What Happens on Approve |
|---|---|---|---|
| `businesses` | `pending` | admin | Sets `status=approved`, `approved_at`, `approved_by`. Becomes visible to public. |
| `deals` | `pending` | admin | Sets `status=approved`. Visible to public. |
| `reviews` | `pending` | admin | Sets `status=approved`. Visible to public. |
| `blog_posts` | `pending` | admin | Sets `status=approved`, `published_at`. Visible to public. |
| `business_images` | `pending` | admin | Sets `status=approved`. Visible in gallery. |
| `category_banners` | `pending` | admin | Sets `status=approved`. Visible on category page. |
| `business_events` | `pending` | admin | Sets `status=approved`. Visible to public. |
| `business_claims` | `pending` | admin | Sets `status=approved`. Trigger `on_business_claim_approved` adds the user to `business_managers` and sets `user_roles.role` to `business_owner`. |

### Actions Requiring Admin

- Approve/reject any moderated content
- Delete businesses
- Manage user roles
- Manage email templates
- View audit log
- Manage notification banners
- Manage categories and subcategories

---

## 4. Loyalty System Architecture

### Token Lifecycle

```
Customer opens punch card
        │
        ▼
[punch-token-generate] ── JWT auth ──▶ Verify card ownership
        │                                      │
        ▼                                      ▼
  crypto.getRandomValues(32 bytes)      INSERT into punch_tokens
        │                              (RLS: user_id must match)
        ▼
  Return 64-char hex token
  (displayed as QR code, valid 5 min)
        │
        ▼
Business owner scans QR
        │
        ▼
[punch-validate] ── JWT auth ──▶ Extract business_owner user_id
        │
        ▼
  serviceClient.rpc('validate_and_punch')
        │
        ▼
  ┌─── validate_and_punch() ───┐
  │ 1. Lookup token (FOR UPDATE)│
  │ 2. Check is_used = false    │
  │ 3. Check created_at > -5min │
  │ 4. Get punch card (FOR UPD) │
  │ 5. Check not redeemed       │
  │ 6. Get program → business   │
  │ 7. is_business_manager()    │
  │ 8. Check < punches_required │
  │ 9. INCREMENT current_punches│
  │10. INSERT punch_history     │
  │11. Mark token used          │
  │12. Return JSON result       │
  └─────────────────────────────┘
```

### Edge Function Responsibilities

| Function | Auth | Input | Action | Uses Service Role |
|---|---|---|---|---|
| `punch-token-generate` | Customer JWT | `user_punch_card_id` | Generates token, inserts via RLS | No (uses anon + user JWT) |
| `punch-validate` | Business owner JWT | `punch_token` | Calls `validate_and_punch` RPC | Yes (to bypass RLS on token/card updates) |

### DB Functions Involved

| Function | Type | Called By |
|---|---|---|
| `validate_and_punch(p_token, p_punched_by)` | SECURITY DEFINER, returns JSONB | `punch-validate` edge function |
| `redeem_punch_card(p_card_id, p_redeemed_by)` | SECURITY DEFINER, returns JSONB | Future redemption flow |
| `is_business_manager(user_id, business_id)` | SECURITY DEFINER, returns boolean | Called within validate/redeem functions |

### Fraud Prevention Mechanisms

| Attack Vector | Prevention |
|---|---|
| **Replay attack** (reuse token) | `is_used` flag checked + `FOR UPDATE` row lock |
| **Expired token** | 5-minute TTL enforced in SQL: `created_at < now() - interval '5 minutes'` |
| **Cross-business abuse** | `is_business_manager()` check ties token → card → program → business → manager |
| **Client-side punch increment** | No UPDATE RLS policy on `user_punch_cards` for non-admin users |
| **Self-service redemption** | `redeem_punch_card()` requires `is_business_manager()` verification |
| **Token guessing** | 256-bit cryptographic randomness (32 bytes → 64 hex chars) |
| **Race condition** | `SELECT ... FOR UPDATE` on both `punch_tokens` and `user_punch_cards` |

---

## 5. Deals System Flow

### Claim Process

1. User calls `INSERT INTO user_deals (user_id, deal_id)` with `user_id = auth.uid()`
2. RLS `WITH CHECK` enforces `user_id = auth.uid()`
3. Unique constraint `(user_id, deal_id)` prevents double-claiming
4. `claimed_at` defaults to `now()`

### Redemption Process

- `used_at` field exists but **no automated redemption flow is built yet**
- Currently requires admin to UPDATE via dashboard or a future edge function
- ⚠️ *No `redeem_deal()` SECURITY DEFINER function exists yet*

### Abuse Prevention

| Constraint | Purpose |
|---|---|
| `UNIQUE (user_id, deal_id)` | One claim per user per deal |
| No user UPDATE policy | Users cannot modify `used_at` or `claimed_at` |
| `deal.is_active` + `status=approved` | Only active, approved deals are visible |

---

## 6. Business Claim Flow

### Current State

1. User inserts into `business_claims` with `user_id = auth.uid()`
2. Admin reviews in dashboard, sets `status = 'approved'`
3. **⚠️ Manual steps required after approval (not automated):**
   - Insert row into `business_managers (business_id, user_id, role='owner')`
   - Insert `business_owner` role into `user_roles` if not present

### Claim Approval Automation

Trigger `on_business_claim_approved` on `business_claims` (AFTER UPDATE when `status` becomes `approved`):
- Inserts into `business_managers` (business_id, user_id, role='owner')
- Sets `user_roles.role` to `business_owner` (insert or update)
- Send notification to user remains app-side (e.g. claim_approved email)

---

## 7. Public Data Exposure Boundary

### Publicly Readable (no auth required)

| Table | Condition |
|---|---|
| `businesses` | `status = 'approved'` only |
| `business_categories` | All rows |
| `subcategories` | All rows |
| `business_subcategories` | All rows |
| `business_hours` | All rows |
| `business_links` | All rows |
| `menu_sections` | All rows |
| `menu_items` | All rows |
| `punch_card_programs` | All rows |
| `blog_posts` | `status = 'approved'` only |
| `business_images` | `status = 'approved'` only |
| `business_events` | `status = 'approved'` only |
| `category_banners` | `status = 'approved'` only |
| `notification_banners` | `is_active = true` only |

### Never Publicly Exposed

| Table | Reason |
|---|---|
| `profiles` | PII — own user only |
| `user_roles` | Security — own user only |
| `user_deals` | Personal data — own user only |
| `user_punch_cards` | Personal data — own user only |
| `punch_tokens` | Security tokens — own user only |
| `punch_history` | Personal data — own user only |
| `event_rsvps` | Personal data — own user only |
| `favorites` | Personal data — own user only |
| `notifications` | Personal data — own user only |
| `audit_log` | Admin only |
| `email_templates` | Admin only |
| `business_managers` | Admin or own business managers only |
| `business_claims` | Own or admin only |
| `reviews` (pending) | Own or admin only until approved |
| `deals` (pending) | Manager or admin only until approved |

### WordPress / External API Boundary

If WordPress or any external system reads Supabase data:
- **Allowed**: Any table marked "publicly readable" above, using the **anon key** (RLS enforces filtering)
- **Must never be exposed**: Service role key, user PII, pending/rejected content, auth tokens
- **Recommended**: Use a read-only Supabase REST endpoint with anon key, never service role

---

## 8. Edge Functions

| Name | Purpose | Auth | Env Vars Required |
|---|---|---|---|
| `punch-token-generate` | Customer generates a one-time QR token for their punch card | User JWT | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| `punch-validate` | Business owner scans QR, validates and records punch | Business owner JWT | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` |
| `stripe-checkout` | Creates Stripe Checkout Session for subscriptions/ads | User JWT | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_SECRET_KEY` |
| `check-subscription` | Checks user's active Stripe subscription status | User JWT | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_SECRET_KEY` |
| `customer-portal` | Creates Stripe Customer Portal session for billing management | User JWT | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_SECRET_KEY` |
| `send-email` | Sends a templated email: loads template from `email_templates`, substitutes `{{variables}}`, sends via SendGrid | User JWT or app | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SENDGRID_API_KEY`; optional: `SENDGRID_FROM_EMAIL`, `SENDGRID_FROM_NAME` |
| `send-templated-email` | Same as `send-email` (templated send via SendGrid) | User JWT or app | Same as `send-email` |
| `process-email-queue` | Processes `email_queue`: sends pending rows via SendGrid, marks sent/failed. Invoke by cron or manually | No JWT (cron) | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SENDGRID_API_KEY`; optional: `SENDGRID_FROM_EMAIL`, `SENDGRID_FROM_NAME` |

### Config

```toml
# supabase/config.toml
[functions.punch-token-generate]
verify_jwt = false   # JWT validated in code via getClaims()

[functions.punch-validate]
verify_jwt = false   # JWT validated in code via getClaims()

[functions.stripe-checkout]
verify_jwt = false   # JWT validated in code via getUser()

[functions.check-subscription]
verify_jwt = false   # JWT validated in code via getUser()

[functions.customer-portal]
verify_jwt = false   # JWT validated in code via getUser()
```

---

## 9. Triggers

| Trigger | Table | Function | Purpose |
|---|---|---|---|
| `on_auth_user_created` | `auth.users` | `handle_new_user()` | Creates profile + assigns `user` role |
| `update_*_updated_at` | 14 tables | `update_updated_at_column()` | Auto-sets `updated_at = now()` on UPDATE |
| `trigger_on_business_claim_approved` | `business_claims` | `on_business_claim_approved()` | Adds manager + business_owner role on approval |
| `trigger_claim_approved_send_email` | `business_claims` | `on_business_claim_approved_send_email()` | Enqueues `claim_approved` email to claimant |
| `trigger_business_approved_send_email` | `businesses` | `on_business_approved_send_email()` | Enqueues `business_approved` email to creator |
| `trigger_deal_approved_send_email` | `deals` | `on_deal_approved_send_email()` | Enqueues `deal_approved` email to business owner |
| `trigger_review_approved_send_email` | `reviews` | `on_review_approved_send_email()` | Enqueues `review_approved` email to reviewer |
| `trigger_business_image_approved_send_email` | `business_images` | `on_business_image_approved_send_email()` | Enqueues `image_approved` email to business owner |
| `trigger_deal_tier_check` | `deals` | `on_deal_before_insert_update_tier_check()` | Enforces business tier: max active deals and advanced deal types (flash, member_only) only for Local Partner |
| `trigger_punch_card_tier_check` | `punch_card_programs` | `on_punch_card_before_insert_tier_check()` | Allows INSERT only when business has Local Partner tier |
| `trigger_business_subscription_pause_excess_deals` | `business_subscriptions` | `on_business_subscription_change_pause_excess_deals()` | On plan/status change: pauses excess active deals when tier downgrade would exceed new limit |

### Business subscription and deals

Deal creation and punch-card creation are enforced by **business subscription tier** (from `business_subscriptions` + `business_plans.tier`):

- **Tier source:** Active row in `business_subscriptions` (status = active) joined to `business_plans`; tier values `free`, `basic`, `premium`, `enterprise`. No subscription or tier `free` → Free; `basic` → Local+; `premium` or `enterprise` → Local Partner.
- **Max active deals:** Free = 1, Local+ (basic) = 3, Local Partner (premium/enterprise) = effectively unlimited.
- **Deal types:** Simple types (`percentage`, `fixed`, `bogo`, `freebie`, `other`) are allowed for all tiers subject to the active-deal limit. Advanced types (`flash`, `member_only`) are allowed only for Local Partner; triggers raise if a lower tier tries to create or activate them.
- **Punch cards:** Only Local Partner can create rows in `punch_card_programs`; trigger blocks INSERT for Free/Local+.
- **Downgrade:** When `business_subscriptions` is updated (e.g. plan_id or status), a trigger runs `pause_excess_deals_for_business(business_id)`, which sets `is_active = false` on excess active deals (oldest by id) so the business stays within the new tier’s limit.

Helper functions (SECURITY DEFINER): `get_business_tier_for_deals(business_id)`, `check_deal_insert_allowed(...)`, `check_punch_card_insert_allowed(business_id)`, `pause_excess_deals_for_business(business_id)`.

### Tables with `updated_at` Trigger

blog_posts, business_categories, business_claims, business_events, businesses, deals, email_templates, event_rsvps, menu_items, menu_sections, notification_banners, profiles, punch_card_programs, reviews, subcategories

---

## 10. Migration & Versioning Structure

### Where Migrations Live

```
supabase/
  migrations/           # Versioned SQL migration files (timestamped)
  functions/
    punch-token-generate/
    punch-validate/
    send-email/           # Templated email via SendGrid (email_templates)
    send-templated-email/ # Same as send-email
    process-email-queue/  # Sends pending email_queue rows via SendGrid
  config.toml             # Function config (verify_jwt settings)
```

### Deployment Process

1. **Migrations**: Created via Lovable migration tool → stored in `supabase/migrations/` → executed against Supabase project
2. **Edge Functions**: Written in repo → auto-deployed by Lovable on save → accessible at `{SUPABASE_URL}/functions/v1/{function-name}`
3. **Secrets**: Managed via Supabase dashboard or Lovable secrets tool. Never in code.

---

## 11. Indexes & Performance

### Custom Indexes

| Index | Table | Columns | Type |
|---|---|---|---|
| `idx_audit_log_user_id` | audit_log | user_id | btree |
| `idx_blog_posts_status` | blog_posts | status | btree |
| `idx_business_events_business_id` | business_events | business_id | btree |
| `idx_business_events_event_date` | business_events | event_date | btree |
| `idx_business_events_status` | business_events | status | btree |
| `idx_businesses_category_id` | businesses | category_id | btree |
| `idx_businesses_city` | businesses | city | btree |
| `idx_businesses_status` | businesses | status | btree |
| `idx_deals_business_id` | deals | business_id | btree |
| `idx_deals_status` | deals | status | btree |
| `idx_event_rsvps_event_id` | event_rsvps | event_id | btree |
| `idx_event_rsvps_user_id` | event_rsvps | user_id | btree |
| `idx_favorites_user_id` | favorites | user_id | btree |
| `idx_punch_tokens_token` | punch_tokens | token | btree |
| `idx_punch_tokens_user_punch_card_id` | punch_tokens | user_punch_card_id | btree |
| `idx_notifications_user_id` | notifications | user_id | btree |
| `idx_reviews_business_id` | reviews | business_id | btree |
| `idx_reviews_status` | reviews | status | btree |

### Unique Constraints (Also Serve as Indexes)

Recommended for data integrity. Ensure the live DB has these; add via migration if missing.

| Table | Columns |
|---|---|
| `favorites` | (user_id, business_id) |
| `user_deals` | (user_id, deal_id) |
| `profiles` | (user_id) |
| `business_managers` | (business_id, user_id) |
| `event_rsvps` | (event_id, user_id) |
| `business_hours` | (business_id, day_of_week) |
| `business_subcategories` | (business_id, subcategory_id) |
| `business_categories` | (name) |
| `blog_posts` | (slug) |
| `email_templates` | (name) |
| `punch_tokens` | (token) |

### Performance Notes

- Supabase default query limit: **1000 rows**. Paginate any listing query.
- `punch_tokens` should be periodically cleaned (expired + used tokens). Consider a scheduled function.
- `FOR UPDATE` locks in `validate_and_punch()` prevent race conditions but may cause contention under very high scan volume.
- All status-filtered public queries benefit from btree indexes on `status` columns.

---

## 12. Storage Buckets (7 Buckets)

All buckets are **public for reading**. Upload/update/delete is scoped via RLS on `storage.objects`.

### File Path Convention

```text
avatars/{user_id}/{filename}
business-images/{business_id}/{filename}
ad-images/{business_id}/{filename}
event-images/{business_id}/{filename}
menu-images/{business_id}/{filename}
blog-images/{any}/{filename}
category-banners/{any}/{filename}
```

RLS policies use `(storage.foldername(name))[1]` to extract the first path segment and match against user/business ownership.

### Bucket Summary

| Bucket | Used By | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|---|
| `avatars` | `profiles.avatar_url` | Public | Own user (`folder[1] = auth.uid()`) |
| `business-images` | `businesses.cover_image_url`, `business_images.url` | Public | Admin OR `is_business_manager(uid, folder[1])` |
| `blog-images` | `blog_posts.cover_image_url` | Public | Admin only |
| `category-banners` | `category_banners.image_url` | Public | Admin only |
| `ad-images` | `business_ads.image_url` | Public | Admin OR `is_business_manager(uid, folder[1])` |
| `event-images` | `business_events.image_url` | Public | Admin OR `is_business_manager(uid, folder[1])` |
| `menu-images` | `menu_items.image_url` | Public | Admin OR `is_business_manager(uid, folder[1])` |

---

## 13. Known Gaps / Future Work

| Gap | Description | Priority |
|---|---|---|
| Claim approval automation | No trigger/function auto-creates `business_managers` entry or grants `business_owner` role on claim approval | High |
| Deal redemption function | No `redeem_deal()` SECURITY DEFINER function for marking `used_at` | Medium |
| Token cleanup | No scheduled job to purge expired/used `punch_tokens` | Low |
| Review aggregation | No materialized view or cached average rating per business | Low |
| Email queue cron | Run `process-email-queue` on a schedule (e.g. every 1–5 min) so enqueued approval emails are sent | Low |