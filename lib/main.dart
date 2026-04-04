import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/app/app.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/revenuecat/revenuecat_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RevenueCatService? revenueCatService;

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    revenueCatService = await RevenueCatService.configure();
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => ProviderScope(
        overrides: [if (revenueCatService != null) revenueCatServiceProvider.overrideWithValue(revenueCatService)],
        child: const SizedBox.expand(child: CajunLocalApp()),
      ),
    ),
  );
}
