import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
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
  runApp(const SizedBox.expand(child: CajunLocalApp()));
}
