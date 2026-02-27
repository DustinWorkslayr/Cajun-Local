import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:my_app/core/revenuecat/revenuecat_config.dart';

// Use default API key. Set [RevenueCatConfig.iosApiKey] / [androidApiKey] for platform-specific keys.

/// Result of presenting a paywall.
enum PaywallPresentationResult {
  notPresented,
  purchased,
  restored,
  cancelled,
  error,
}

/// RevenueCat service: initialization, entitlement checking (Cajun+),
/// customer info, paywall and Customer Center presentation.
/// Initialize once from [main] before [runApp]; call [logIn] when user signs in.
class RevenueCatService {
  RevenueCatService() {
    _customerInfoController = ValueNotifier<CustomerInfo?>(null);
  }

  static const String _tag = 'RevenueCatService';

  ValueNotifier<CustomerInfo?> get customerInfo => _customerInfoController!;
  ValueNotifier<CustomerInfo?>? _customerInfoController;

  bool _configured = false;

  /// Whether the SDK has been configured (e.g. from main).
  bool get isConfigured => _configured;

  /// Entitlement ID used for Cajun+ (from config).
  String get cajunPlusEntitlementId => RevenueCatConfig.cajunPlusEntitlementId;

  /// Configure RevenueCat. Call once from main() before runApp().
  /// [appUserId] can be null for anonymous users; call [logIn] after sign-in.
  static Future<RevenueCatService> configure({String? appUserId}) async {
    final service = RevenueCatService();
    await service._configure(appUserId: appUserId);
    return service;
  }

  Future<void> _configure({String? appUserId}) async {
    if (_configured) return;
    if (kIsWeb) return; // IAP not supported on web; use RevenueCat Web Billing if needed.
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      final apiKey = RevenueCatConfig.apiKey;
      final config = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId;
      await Purchases.configure(config);
      _configured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      final info = await Purchases.getCustomerInfo();
      _customerInfoController?.value = info;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag configure error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    _customerInfoController?.value = info;
  }

  /// Identify the user with RevenueCat after sign-in. Call when auth state
  /// changes to a logged-in user. Pass null on log-out to reset to anonymous.
  Future<void> logIn(String? userId) async {
    if (!_configured) return;
    try {
      if (userId == null || userId.isEmpty) {
        await Purchases.logOut();
        _customerInfoController?.value = null;
        return;
      }
      final loginResult = await Purchases.logIn(userId);
      _customerInfoController?.value = loginResult.customerInfo;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag logIn error: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  /// Returns true if the user has the Cajun+ entitlement active.
  bool get isCajunPlusActive {
    final info = _customerInfoController?.value;
    if (info == null) return false;
    return info.entitlements.all[RevenueCatConfig.cajunPlusEntitlementId]?.isActive ?? false;
  }

  /// Async check: fetch latest customer info and return whether Cajun+ is active.
  Future<bool> checkCajunPlusActive() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      _customerInfoController?.value = info;
      return info.entitlements.all[RevenueCatConfig.cajunPlusEntitlementId]?.isActive ?? false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag getCustomerInfo error: $e');
        debugPrintStack(stackTrace: st);
      }
      return false;
    }
  }

  /// Get current customer info (cached or fetch).
  Future<CustomerInfo?> getCustomerInfo({bool forceRefresh = false}) async {
    if (!_configured) return null;
    try {
      final info = await Purchases.getCustomerInfo();
      if (forceRefresh) _customerInfoController?.value = info;
      return info;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag getCustomerInfo error: $e');
        debugPrintStack(stackTrace: st);
      }
      return _customerInfoController?.value;
    }
  }

  /// Get available offerings (products: monthly, yearly). Configure in RevenueCat Dashboard.
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag getOfferings error: $e');
        debugPrintStack(stackTrace: st);
      }
      return null;
    }
  }

  /// Present the RevenueCat Paywall (Cajun+ / user_plans). Use when user taps "Subscribe" or "See plans".
  /// Returns how the paywall was dismissed (purchased, restored, cancelled, error).
  Future<PaywallPresentationResult> presentPaywall() async {
    if (!_configured) return PaywallPresentationResult.error;
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.all[RevenueCatConfig.offeringId] ?? offerings.current;
      if (offering != null) {
        final result = await RevenueCatUI.presentPaywall(offering: offering);
        return _mapPaywallResult(result);
      }
      final result = await RevenueCatUI.presentPaywall();
      return _mapPaywallResult(result);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag presentPaywall error: $e');
        debugPrintStack(stackTrace: st);
      }
      return PaywallPresentationResult.error;
    }
  }

  /// Present the Paywall only if the user does not have the Cajun+ entitlement.
  /// Returns [PaywallPresentationResult.notPresented] if they already have access.
  Future<PaywallPresentationResult> presentPaywallIfNeeded() async {
    if (!_configured) return PaywallPresentationResult.error;
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        RevenueCatConfig.cajunPlusEntitlementId,
      );
      return _mapPaywallResult(result);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag presentPaywallIfNeeded error: $e');
        debugPrintStack(stackTrace: st);
      }
      return PaywallPresentationResult.error;
    }
  }

  static PaywallPresentationResult _mapPaywallResult(PaywallResult result) {
    switch (result) {
      case PaywallResult.notPresented:
        return PaywallPresentationResult.notPresented;
      case PaywallResult.purchased:
        return PaywallPresentationResult.purchased;
      case PaywallResult.restored:
        return PaywallPresentationResult.restored;
      case PaywallResult.cancelled:
        return PaywallPresentationResult.cancelled;
      case PaywallResult.error:
        return PaywallPresentationResult.error;
    }
  }

  /// Present the Customer Center so the user can manage subscription, restore, etc.
  /// Call from Profile / Settings when the user taps "Manage subscription".
  Future<void> presentCustomerCenter({
    void Function(CustomerInfo)? onRestoreCompleted,
    void Function(String productId, String status)? onRefundRequestCompleted,
  }) async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: onRestoreCompleted,
        onRefundRequestCompleted: onRefundRequestCompleted,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('$_tag presentCustomerCenter error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  /// Remove listener and clean up. Call from app dispose if needed.
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
    _customerInfoController?.dispose();
    _customerInfoController = null;
  }
}
