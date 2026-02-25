# Cajun Local — Stripe Integration Cheat Sheet

> Technical reference. Edge functions, payment flows, metadata conventions.
> Last updated: 2026-02-22
>
> **See also:**
> - [Pricing, Subscriptions & Advertising Cheat Sheet](./pricing-and-ads-cheatsheet.md) — DB tables for monetization.
> - [Backend Architecture Cheat Sheet](./backend-cheatsheet.md) — full backend reference.

---

## 1. Edge Functions (3)

| Function | Method | Auth | Purpose |
|---|---|---|---|
| `stripe-checkout` | POST | User JWT | Creates a Stripe Checkout Session |
| `check-subscription` | POST | User JWT | Checks active subscription status |
| `customer-portal` | POST | User JWT | Creates Stripe Customer Portal session |

All functions: `verify_jwt = false` in `config.toml`; JWT validated in code via `supabase.auth.getUser(token)`.

---

## 2. stripe-checkout

### Request

```
POST /functions/v1/stripe-checkout
Authorization: Bearer <user_jwt>
Content-Type: application/json
```

```json
{
  "price_id": "price_abc123",
  "mode": "subscription",
  "success_url": "https://app.example.com/dashboard?checkout=success",
  "cancel_url": "https://app.example.com/dashboard?checkout=canceled",
  "metadata": {
    "type": "business_subscription",
    "business_id": "uuid-here",
    "reference_id": "uuid-of-plan-or-ad"
  }
}
```

| Field | Required | Default | Notes |
|---|---|---|---|
| `price_id` | Yes | — | Stripe Price ID |
| `mode` | No | `"subscription"` | `"subscription"` or `"payment"` |
| `success_url` | No | `{origin}/dashboard?checkout=success` | Redirect after success |
| `cancel_url` | No | `{origin}/dashboard?checkout=canceled` | Redirect on cancel |
| `metadata` | No | `{}` | Attached to Checkout Session; see §5 |

### Response

```json
{ "url": "https://checkout.stripe.com/c/pay/cs_..." }
```

### Behavior

1. Authenticates user via JWT
2. Looks up Stripe customer by email; creates one if none exists
3. Creates Checkout Session with the given price, mode, and metadata
4. Returns the checkout URL for client-side redirect

---

## 3. check-subscription

### Request

```
POST /functions/v1/check-subscription
Authorization: Bearer <user_jwt>
```

No body required.

### Response (subscribed)

```json
{
  "subscribed": true,
  "product_id": "prod_abc123",
  "subscription_end": "2026-03-22T00:00:00.000Z",
  "subscriptions": [
    {
      "subscription_id": "sub_abc123",
      "product_id": "prod_abc123",
      "price_id": "price_abc123",
      "subscription_end": "2026-03-22T00:00:00.000Z",
      "metadata": {}
    }
  ]
}
```

### Response (not subscribed)

```json
{ "subscribed": false }
```

### Frontend Usage

Call on:
- Login / auth state change
- Page load
- Periodically (every 60s recommended)
- After returning from checkout success URL

---

## 4. customer-portal

### Request

```
POST /functions/v1/customer-portal
Authorization: Bearer <user_jwt>
Content-Type: application/json
```

```json
{ "return_url": "https://app.example.com/settings" }
```

`return_url` is optional; defaults to `{origin}/dashboard`.

### Response

```json
{ "url": "https://billing.stripe.com/p/session/..." }
```

### Prerequisites

The Stripe Customer Portal must be configured in the Stripe Dashboard:
https://docs.stripe.com/customer-management/activate-no-code-customer-portal

---

## 5. Metadata Convention

All Checkout Sessions include metadata for linking Stripe events back to DB records:

| Key | Values | Purpose |
|---|---|---|
| `supabase_user_id` | UUID | Always set automatically from JWT |
| `type` | `business_subscription`, `user_subscription`, `advertisement` | Identifies which DB table to update |
| `business_id` | UUID | For business subs and ads |
| `reference_id` | UUID | Points to `business_plans.id`, `user_plans.id`, or `ad_packages.id` |

---

## 6. Stripe Products / Prices Mapping (DB-Driven)

Stripe Price IDs are stored directly in the plan tables. The frontend fetches them dynamically — no hardcoded constants needed.

### DB Columns

| Table | Column | Purpose |
|---|---|---|
| `business_plans` | `stripe_price_id_monthly` | Stripe Price ID for monthly billing |
| `business_plans` | `stripe_price_id_yearly` | Stripe Price ID for yearly billing |
| `business_plans` | `stripe_product_id` | Stripe Product ID for tier mapping |
| `user_plans` | `stripe_price_id_monthly` | Stripe Price ID for monthly billing |
| `user_plans` | `stripe_price_id_yearly` | Stripe Price ID for yearly billing |
| `user_plans` | `stripe_product_id` | Stripe Product ID for tier mapping |
| `ad_packages` | `stripe_price_id` | Stripe Price ID (one-time payment) |

All columns are nullable text. Populated by admin after creating products in Stripe Dashboard.

### Frontend Flow

1. Fetch the plan row from `business_plans` or `user_plans`
2. Read `stripe_price_id_monthly` or `stripe_price_id_yearly` based on selected billing interval
3. Pass the `price_id` to `stripe-checkout`

```typescript
// Example: fetch price ID for a business plan
const { data: plan } = await supabase
  .from('business_plans')
  .select('stripe_price_id_monthly, stripe_price_id_yearly')
  .eq('id', selectedPlanId)
  .single();

const priceId = interval === 'yearly'
  ? plan.stripe_price_id_yearly
  : plan.stripe_price_id_monthly;

// Then call stripe-checkout with priceId
```

### Ad Packages

For one-time ad purchases, read `stripe_price_id` from `ad_packages`:

```typescript
const { data: pkg } = await supabase
  .from('ad_packages')
  .select('stripe_price_id')
  .eq('id', selectedPackageId)
  .single();

// Call stripe-checkout with pkg.stripe_price_id and mode: "payment"
```

---

## 7. Checkout Flows

### Subscription Flow (Business or User)

```
Frontend                    stripe-checkout              Stripe
   │                              │                        │
   │── POST {price_id, mode,     │                        │
   │   metadata} ──────────────► │                        │
   │                              │── Create/find customer │
   │                              │── Create session ─────►│
   │                              │◄─ session.url ─────────│
   │◄── { url } ─────────────────│                        │
   │                              │                        │
   │── redirect to url ──────────────────────────────────►│
   │                              │                        │
   │◄── redirect to success_url ──────────────────────────│
   │                              │                        │
   │── check-subscription ──────►│                        │
   │◄── { subscribed: true } ────│                        │
```

### Ad Purchase Flow (One-Time)

Same as above but with `mode: "payment"` and `metadata.type: "advertisement"`.

---

## 8. Webhook Event Matrix (Future)

When a Stripe webhook function is built, these events should update DB tables:

| Stripe Event | Action | DB Table |
|---|---|---|
| `checkout.session.completed` | Create subscription/payment record | `business_subscriptions`, `user_subscriptions`, `payment_history` |
| `invoice.payment_succeeded` | Update period dates | `business_subscriptions`, `user_subscriptions` |
| `invoice.payment_failed` | Set status to `past_due` | `business_subscriptions`, `user_subscriptions` |
| `customer.subscription.updated` | Sync status, period | `business_subscriptions`, `user_subscriptions` |
| `customer.subscription.deleted` | Set status to `canceled` | `business_subscriptions`, `user_subscriptions` |

**Secret required**: `STRIPE_WEBHOOK_SECRET` (not yet configured — needed when webhook is built).

---

## 9. Secrets

| Secret | Status | Used By |
|---|---|---|
| `STRIPE_SECRET_KEY` | ✅ Configured | All 3 edge functions |
| `STRIPE_WEBHOOK_SECRET` | ⏳ Not yet | Future webhook function |

---

## 10. Security Notes

- **STRIPE_SECRET_KEY** is only accessible in edge functions (server-side). Never exposed to frontend.
- All functions validate JWT in code; `verify_jwt = false` in config to use signing-keys approach.
- Stripe customer is matched by **email** (from `auth.users`).
- `supabase_user_id` is always embedded in checkout metadata for traceability.
- No raw SQL is executed; all DB access via typed Supabase client or RPC.

---

## 11. Config

```toml
# supabase/config.toml (additions)
[functions.stripe-checkout]
verify_jwt = false

[functions.check-subscription]
verify_jwt = false

[functions.customer-portal]
verify_jwt = false
```

---

## 12. Known Gaps / Future Work

| Gap | Description | Priority |
|---|---|---|
| Stripe webhook handler | No edge function to receive Stripe events and sync DB | High |
| Stripe products/prices | No products created yet in Stripe Dashboard; once created, populate `stripe_price_id_*` and `stripe_product_id` columns in `business_plans`, `user_plans`, and `ad_packages` | High |
| Ad payment flow | `business_ads.status` not updated after payment | Medium |
| Subscription sync | `business_subscriptions` / `user_subscriptions` not updated from Stripe | High |
