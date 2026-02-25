/// Supabase project URL and anon key.
/// Replace with your project values from https://supabase.com/dashboard/project/_/settings/api
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qfcaxmlstwlutoojzcuq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmY2F4bWxzdHdsdXRvb2p6Y3VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MjQxNjYsImV4cCI6MjA4NzIwMDE2Nn0.CR4LulzY6aAiQX2j-hQtZvmJdXJ1EhuSwJ3puuTVHoE',
  );

  /// True when real credentials are set (app can run without Supabase until then).
  static bool get isConfigured =>
      !url.contains('YOUR_') && !anonKey.contains('YOUR_');
}
