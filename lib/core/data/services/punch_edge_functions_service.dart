import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Invokes punch-related Supabase edge functions (backend-cheatsheet §4, §8).
/// punch-token-generate: customer JWT, input user_punch_card_id → 64-char hex token.
/// punch-validate: business owner JWT, input punch_token → validate_and_punch result.
class PunchEdgeFunctionsService {
  PunchEdgeFunctionsService();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Generate a one-time punch token for the given user punch card (customer).
  /// Returns the 64-char hex token to display as QR. Valid ~5 min.
  /// Throws on failure or if not signed in.
  Future<String> generatePunchToken(String userPunchCardId) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    if (client.auth.currentUser == null) throw StateError('Must be signed in to generate punch token');
    final response = await client.functions.invoke(
      'punch-token-generate',
      body: {'user_punch_card_id': userPunchCardId},
    );
    if (response.status != 200) {
      final msg = response.data is Map ? (response.data as Map)['message']?.toString() : null;
      throw PunchTokenException(msg ?? response.data?.toString() ?? 'Failed to generate token');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) throw PunchTokenException('Invalid response');
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) throw PunchTokenException('No token in response');
    return token;
  }

  /// Validate a punch token (business owner). Calls punch-validate edge function.
  /// [punches] optional: number of punches to award for this scan (default 1). Backend must support it.
  /// Returns the result message or throws.
  Future<PunchValidateResult> validatePunch(String punchToken, {int punches = 1}) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    if (client.auth.currentUser == null) throw StateError('Must be signed in to validate punch');
    final body = <String, dynamic>{
      'punch_token': punchToken.trim(),
      if (punches > 1) 'punches': punches,
    };
    final response = await client.functions.invoke(
      'punch-validate',
      body: body,
    );
    if (response.status != 200) {
      final msg = response.data is Map ? (response.data as Map)['message']?.toString() : null;
      throw PunchTokenException(msg ?? response.data?.toString() ?? 'Validation failed');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) return PunchValidateResult(success: false, message: 'Invalid response');
    final success = data['success'] as bool? ?? false;
    final message = data['message'] as String? ?? (success ? 'Punch recorded' : 'Unknown error');
    return PunchValidateResult(success: success, message: message);
  }
}

class PunchTokenException implements Exception {
  PunchTokenException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PunchValidateResult {
  const PunchValidateResult({required this.success, this.message});
  final bool success;
  final String? message;
}
