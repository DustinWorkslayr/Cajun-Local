import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/app/app.dart';
import 'package:cajun_local/core/revenuecat/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize RevenueCat (no-op on web; requires iOS/Android for IAP).
  final revenueCatService = await RevenueCatService.configure();
  runApp(
    ProviderScope(
      child: SizedBox.expand(child: CajunLocalApp(revenueCatService: revenueCatService)),
    ),
  );
}
