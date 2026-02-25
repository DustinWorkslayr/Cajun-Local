import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Invokes the send-email Supabase edge function to send a templated email via SendGrid.
/// Fire-and-forget: does not throw so approval flows are not blocked if email fails.
class SendEmailService {
  SendEmailService();

  static const String _functionName = 'send-email';

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Sends a templated email. [to] is recipient address; [template] is the
  /// email_templates name; [variables] are substituted into template {{keys}}.
  /// No-op if Supabase not configured or [to] is empty. Does not throw.
  Future<void> send({
    required String to,
    required String template,
    required Map<String, String> variables,
  }) async {
    final client = _client;
    if (client == null || to.trim().isEmpty) return;
    try {
      final response = await client.functions.invoke(
        _functionName,
        body: {
          'to': to.trim(),
          'template': template,
          'variables': variables,
        },
      );
      if (response.status != 200) {
        // Log but don't throw; caller flow (e.g. approval) should still succeed
        assert(() {
          // ignore: avoid_print
          print('SendEmailService: $template to $to failed ${response.status} ${response.data}');
          return true;
        }());
      }
    } catch (_) {
      // Fire-and-forget: do not rethrow
    }
  }
}
