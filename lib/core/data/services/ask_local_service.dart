import 'dart:async';

/// Result of calling the ask-local edge function.
/// [AskLocalFailure] carries an app-friendly message and optional code.
sealed class AskLocalResult {}

class AskLocalStream extends AskLocalResult {
  AskLocalStream(this.stream);
  final Stream<String> stream;
}

class AskLocalFailure extends AskLocalResult {
  AskLocalFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Calls the ask-local service.
/// Returns [AskLocalStream] with content chunks
/// or [AskLocalFailure] on auth/subscription/network errors.
class AskLocalService {
  AskLocalService();

  /// Send [question] with [accessToken]. Streams content chunks via [AskLocalStream.stream].
  /// [preferredParishIds] filters results to the user's preferred parishes when non-empty.
  /// On error returns [AskLocalFailure] with message and optional code (e.g. subscription_required).
  Future<AskLocalResult> ask({
    required String question,
    required String accessToken,
    List<String>? preferredParishIds,
  }) async {
    // TODO: Implement AI Chat in FastAPI backend
    return AskLocalFailure('AI Chat is currently undergoing maintenance as we migrate our backend. Check back soon!');
  }
}
