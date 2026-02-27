import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/core/revenuecat/revenuecat_service.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: true,
      ),
    );
  }
  // Initialize RevenueCat (no-op on web; requires iOS/Android for IAP).
  final revenueCatService = await RevenueCatService.configure();
  runApp(SizedBox.expand(
    child: CajunLocalApp(revenueCatService: revenueCatService),
  ));
}
