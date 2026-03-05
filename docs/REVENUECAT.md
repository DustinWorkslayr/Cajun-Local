# RevenueCat integration (Cajun Local)

This app uses RevenueCat on iOS and Android for:

- **Subscriptions (paywalls):** **Cajun+**, **Local+**, and **Local Partner** only. No other subscription tiers.
- **Advertisement / feature payments:** Boosts and feature placements (e.g. homepage feature, category feature) — non-subscription or consumable products. Ad payment is RevenueCat-only: each `ad_packages` row can set `revenuecat_product_id` (e.g. `homepage_feature_7_day`); the Buy ad flow uses `RevenueCatService.purchaseAdProduct()`.

## Already done in code

- **Packages:** `purchases_flutter`, `purchases_ui_flutter` (see `pubspec.yaml`).
- **Config:** `lib/core/revenuecat/revenuecat_config.dart` – API key, entitlement ID `cajun_plus`, offering ID `user_plans`, product IDs reference.
- **Service:** `lib/core/revenuecat/revenuecat_service.dart` – configure, logIn, entitlement check, paywall, Customer Center, `purchaseAdProduct(productId)` for ad IAP.
- **Init:** RevenueCat is configured in `main()` and optional `RevenueCatService` is provided via `AppDataScope`.
- **Paywall:** RevenueCat only — no custom paywall UI. Tapping "Get Cajun+ Membership" or "Subscribe" calls `presentSubscriptionPaywall(context)`, which presents the RevenueCat Paywall directly.
- **Customer Center:** Profile → Billing & subscription → "Manage subscription" opens RevenueCat Customer Center when the service is configured.
- **Android:** `BILLING` permission, `launchMode="singleTop"`, and `MainActivity` extends `FlutterFragmentActivity` (required for Paywalls).

## RevenueCat Dashboard setup

### 1. Project → API keys

- Use the **public** API key in `RevenueCatConfig.apiKey` (already set to your test key).
- For production, set separate `RevenueCatConfig.iosApiKey` and `RevenueCatConfig.androidApiKey` if you have platform-specific keys.

### 2. Entitlements (subscriptions only)

The system has **only three** subscription entitlements for paywalls:

| Entitlement ID   | Description   |
|------------------|---------------|
| `cajun_plus`     | Cajun+ (user-level) |
| `local_plus`     | Local+ (business)   |
| `local_partner`  | Local Partner (business) |

- Create these three entitlements in RevenueCat Dashboard → Entitlements.
- `cajun_plus` must match `RevenueCatConfig.cajunPlusEntitlementId` (used for paywall checks).

### 3. Products

**Subscriptions (for paywalls):** Create in App Store Connect and Google Play Console, then add in RevenueCat Dashboard and link to the entitlements above.

| Product ID | Entitlement   |
|------------|---------------|
| `cajun_plus_monthly` | cajun_plus |
| `cajun_plus_yearly`  | cajun_plus |
| `local_plus_monthly` | local_plus |
| `business_local_plus_yearly` | local_plus |
| `local_partner_monthly` | local_partner |
| `business_local_partner_yearly` | local_partner |

**Advertisement / feature payments:** Non-subscription or consumable; link to entitlements only if you use them for gating.

| Product ID | Notes |
|------------|-------|
| `boost_7_day` | Boost 7 days |
| `homepage_feature_7_day` | Homepage feature 7 days |
| `category_feature_7_day` | Category feature 7 days |
| `feature_monthly` | Feature monthly |

Product IDs must match exactly in App Store Connect and Google Play. Use `business_local_partner_yearly` (not `yealy`).

### 4. Offerings (subscription paywalls)

- Create Offerings that contain **only** Cajun+, Local+, and Local Partner packages (e.g. `user_plans` for user subscriptions, and separate offerings for Local+ / Local Partner if needed).
- Add **Packages** for monthly and yearly products per tier.
- Mark one offering as **Current** for the default paywall.
- Use package identifiers like `$rc_monthly`, `$rc_annual` for RevenueCat Paywall templates.

### 5. Paywalls

- Paywalls in the app show **only** the three subscription tiers: Cajun+, Local+, Local Partner.
- In RevenueCat Dashboard → Paywalls, create paywalls for the offerings you use.
- The Flutter app uses `presentPaywall()` / `presentPaywallIfNeeded("cajun_plus")`; no offering ID is passed by default, so the **current** offering and its paywall are used.

### 6. Customer Center (optional)

- Configure in Dashboard → Customer Center (Pro/Enterprise plans).
- The app calls `RevenueCatUI.presentCustomerCenter()` from Profile when RevenueCat is configured.

## Using the service in code

- **Check Cajun+:** `AppDataScope.of(context).revenueCatService?.isCajunPlusActive` or `checkCajunPlusActive()`.
- **Show paywall:** `await scope.revenueCatService?.presentPaywall()`.
- **Show paywall only if not entitled:** `await scope.revenueCatService?.presentPaywallIfNeeded()`.
- **Customer info:** `scope.revenueCatService?.getCustomerInfo()` or `scope.revenueCatService?.customerInfo.value`.
- **After sign-in:** The app calls `revenueCatService.logIn(userId)` when auth state changes; no extra call needed from feature code.

## Error handling

- `RevenueCatService` catches and logs errors in debug mode; methods return `null` or `false` on failure.
- `presentPaywall()` / `presentPaywallIfNeeded()` return `PaywallPresentationResult` (purchased, restored, cancelled, error).
- `presentCustomerCenter()` supports `onRestoreCompleted`, `onRestoreFailed`, `onRefundRequestCompleted` for user feedback.

## Switching to production

Replace `RevenueCatConfig.apiKey` with your **production** public API key (and set `iosApiKey` / `androidApiKey` if you use separate keys). Ensure products and entitlements are configured for production in App Store Connect and Google Play.
