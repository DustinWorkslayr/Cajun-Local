import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of processing the email queue.
class ProcessEmailQueueResult {
  const ProcessEmailQueueResult({
    required this.processed,
    required this.sent,
    required this.failed,
  });

  final int processed;
  final int sent;
  final int failed;

  factory ProcessEmailQueueResult.fromJson(Map<String, dynamic> json) {
    return ProcessEmailQueueResult(
      processed: (json['processed'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Invokes the process-email-queue edge function. Sends the current user JWT;
/// the function requires admin when Authorization is present.
class ProcessEmailQueueService {
  ProcessEmailQueueService();

  static const String _functionName = 'process-email-queue';

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Processes pending emails. Returns result or throws on error/403.
  Future<ProcessEmailQueueResult> processQueue() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase not configured');
    }
    final response = await client.functions.invoke(_functionName);
    if (response.status != 200) {
      final msg = response.data is Map
          ? (response.data as Map)['error']?.toString()
          : response.data?.toString();
      throw Exception(msg ?? 'Process queue failed (${response.status})');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const ProcessEmailQueueResult(processed: 0, sent: 0, failed: 0);
    }
    return ProcessEmailQueueResult.fromJson(data);
  }
}
