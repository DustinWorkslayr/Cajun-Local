# RevenueCat integration (Cajun Local)

This app uses RevenueCat for Cajun+ in-app subscriptions (monthly/yearly) on iOS and Android.

## Already done in code

- **Packages:** `purchases_flutter`, `purchases_ui_flutter` (see `pubspec.yaml`).
- **Config:** `lib/core/revenuecat/revenuecat_config.dart` – API key and entitlement ID `Cajun+`.
- **Service:** `lib/core/revenuecat/revenuecat_service.dart` – configure, logIn, entitlement check, paywall, Customer Center.
- **Init:** RevenueCat is configured in `main()` and optional `RevenueCatService` is provided via `AppDataScope`.
- **Paywall:** Shown when the user taps “Get Cajun+ Membership” or “Subscribe” in the subscription upsell popup (RevenueCat Paywall when available).
- **Customer Center:** Profile → Billing & subscription → “Manage subscription” opens RevenueCat Customer Center when the service is configured.
- **Android:** `BILLING` permission and `launchMode="singleTop"` in `AndroidManifest.xml`.

## RevenueCat Dashboard setup

1. **Project → API keys**  
   - Use the **public** API key in `RevenueCatConfig.apiKey` (already set to your test key).  
   - For production you can set separate `RevenueCatConfig.iosApiKey` and `RevenueCatConfig.androidApiKey` if you have platform-specific keys.

2. **Entitlements**  
   - Create an entitlement with identifier **exactly** `Cajun+` (matches `RevenueCatConfig.cajunPlusEntitlementId`).

3. **Products**  
   - In App Store Connect and Google Play Console, create:
     - **Monthly** subscription (e.g. product id `monthly`).
     - **Yearly** subscription (e.g. product id `yearly`).  
   - In RevenueCat Dashboard → Products, add these products and link them to the **Cajun+** entitlement.

4. **Offerings**  
   - Create an Offering (e.g. “default”) and add **Packages** that reference your monthly and yearly products.  
   - Mark one offering as **Current** so the paywall uses it when no specific offering is requested.

5. **Paywalls**  
   - In RevenueCat Dashboard → Paywalls, create a paywall for the offering you use.  
   - The Flutter app uses `RevenueCatUI.presentPaywall()` / `presentPaywallIfNeeded("Cajun+")`; no offering ID is passed, so the **current** offering and its paywall are used.

6. **Customer Center** (optional)  
   - Configure in Dashboard → Customer Center.  
   - The app calls `RevenueCatUI.presentCustomerCenter()` from Profile when RevenueCat is configured.

## Optional: Android Paywalls (fullscreen)

If you use RevenueCat Paywalls and see issues when returning from the system purchase UI, ensure `MainActivity` extends `FlutterFragmentActivity` (not `FlutterActivity`). See [RevenueCat Flutter installation](https://www.revenuecat.com/docs/getting-started/installation/flutter#optional-change-mainactivity-subclass).

## Using the service in code

- **Check Cajun+:** `AppDataScope.of(context).revenueCatService?.isCajunPlusActive` or `checkCajunPlusActive()`.
- **Show paywall:** `await scope.revenueCatService?.presentPaywall()`.
- **Show paywall only if not entitled:** `await scope.revenueCatService?.presentPaywallIfNeeded()`.
- **Customer info:** `scope.revenueCatService?.getCustomerInfo()` or `scope.revenueCatService?.customerInfo.value`.
- **After sign-in:** The app calls `revenueCatService.logIn(userId)` when auth state changes; no extra call needed from feature code.

## Switching to production

Replace `RevenueCatConfig.apiKey` with your **production** public API key (and set `iosApiKey` / `androidApiKey` if you use separate keys). Ensure products and entitlements are configured for production in App Store Connect and Google Play.
