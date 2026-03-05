import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/revenuecat/revenuecat_service.dart';

/// Presents the RevenueCat subscription paywall (Cajun+, Local+, Local Partner).
/// Use this instead of any custom paywall UI.
///
/// If RevenueCat is not available (e.g. on web), [onRevenueCatUnavailable] is
/// called if provided (e.g. open Stripe checkout).
Future<void> presentSubscriptionPaywall(
  BuildContext context, {
  VoidCallback? onRevenueCatUnavailable,
}) async {
  final rc = AppDataScope.of(context).revenueCatService;
  if (rc == null) {
    onRevenueCatUnavailable?.call();
    return;
  }
  final result = await rc.presentPaywall();
  if (context.mounted &&
      (result == PaywallPresentationResult.purchased ||
          result == PaywallPresentationResult.restored)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome to Cajun+!')),
    );
  }
}
