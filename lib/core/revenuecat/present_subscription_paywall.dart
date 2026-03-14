import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/revenuecat/revenuecat_service.dart';

/// Presents the RevenueCat subscription paywall (Cajun+, Local+, Local Partner).
/// Use this instead of any custom paywall UI.
///
/// If RevenueCat is not available (e.g. on web), [onRevenueCatUnavailable] is
/// called if provided (e.g. open Stripe checkout).
Future<void> presentSubscriptionPaywall(BuildContext context, WidgetRef ref, {VoidCallback? onRevenueCatUnavailable}) async {
  final rc = ref.read(revenueCatServiceProvider);
  if (rc == null) {
    onRevenueCatUnavailable?.call();
    return;
  }
  final result = await rc.presentPaywall();
  if (context.mounted &&
      (result == PaywallPresentationResult.purchased || result == PaywallPresentationResult.restored)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome to Cajun+!')));
  }
}
