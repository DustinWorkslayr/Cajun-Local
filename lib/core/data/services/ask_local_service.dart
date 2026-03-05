import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_app/core/supabase/supabase_config.dart';

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

/// Calls the ask-local Supabase Edge Function with streaming SSE response.
/// Requires [accessToken] (user JWT). Returns [AskLocalStream] with content chunks
/// or [AskLocalFailure] on auth/subscription/network errors.
class AskLocalService {
  AskLocalService() : _client = http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxAttempts = 2;
  /// Max bytes to read from error response bodies (prevents OOM from huge error payloads).
  static const int _maxErrorBodyBytes = 64 * 1024;

  static String get _baseUrl {
    final url = SupabaseConfig.url;
    if (url.endsWith('/')) return '${url}functions/v1/ask-local';
    return '$url/functions/v1/ask-local';
  }

  /// Send [question] with [accessToken]. Streams content chunks via [AskLocalStream.stream].
  /// [preferredParishIds] filters results to the user's preferred parishes when non-empty.
  /// On error returns [AskLocalFailure] with message and optional code (e.g. subscription_required).
  Future<AskLocalResult> ask({
    required String question,
    required String accessToken,
    List<String>? preferredParishIds,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AskLocalFailure('Service not configured.');
    }
    final uri = Uri.parse(_baseUrl);
    final body = <String, dynamic>{'question': question.trim()};
    if (preferredParishIds != null && preferredParishIds.isNotEmpty) {
      body['preferred_parish_ids'] = preferredParishIds;
    }
    try {
      int attempt = 0;
      http.StreamedResponse? response;
      while (true) {
        attempt++;
        final req = http.Request('POST', uri)
          ..headers['Content-Type'] = 'application/json'
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..body = jsonEncode(body);
        try {
          response = await _client.send(req).timeout(_timeout);
        } on TimeoutException {
          return AskLocalFailure('Request timed out. Please try again.');
        } catch (e) {
          if (attempt < _maxAttempts) {
            await Future<void>.delayed(const Duration(seconds: 2));
            continue;
          }
          rethrow;
        }
        if (response.statusCode >= 500 || response.statusCode == 503) {
          await response.stream.drain();
          if (attempt < _maxAttempts) {
            await Future<void>.delayed(const Duration(seconds: 2));
            continue;
          }
        }
        break;
      }
      final response2 = response;

      if (response2.statusCode == 403) {
        String resBody = '';
        int totalBytes = 0;
        await for (final chunk in response2.stream) {
          totalBytes += chunk.length;
          if (totalBytes > _maxErrorBodyBytes) break;
          resBody += utf8.decode(chunk);
        }
        String? code;
        String message = 'Access denied.';
        try {
          final map = jsonDecode(resBody) as Map<String, dynamic>?;
          if (map != null) {
            code = map['code'] as String?;
            final err = map['error'] as String?;
            if (err != null && err.isNotEmpty) message = err;
          }
        } catch (_) {}
        if (code == 'auth_required' || code == 'auth_invalid') {
          message = 'Sign in again.';
        } else if (code == 'subscription_required') {
          message = 'Ask Local is included with Cajun+ Membership and Pro.';
        }
        return AskLocalFailure(message, code: code);
      }

      if (response2.statusCode == 400) {
        String resBody = '';
        int totalBytes = 0;
        await for (final chunk in response2.stream) {
          totalBytes += chunk.length;
          if (totalBytes > _maxErrorBodyBytes) break;
          resBody += utf8.decode(chunk);
        }
        try {
          final map = jsonDecode(resBody) as Map<String, dynamic>?;
          final err = map?['error'] as String?;
          if (err != null && err.isNotEmpty) {
            return AskLocalFailure(err);
          }
        } catch (_) {}
        return AskLocalFailure('A question is required.');
      }

      if (response2.statusCode != 200) {
        String resBody = '';
        int totalBytes = 0;
        await for (final chunk in response2.stream) {
          totalBytes += chunk.length;
          if (totalBytes > _maxErrorBodyBytes) break;
          resBody += utf8.decode(chunk);
        }
        if (response2.statusCode == 503) {
          return AskLocalFailure('Request timed out. Please try again.');
        }
        if (response2.statusCode == 429) {
          return AskLocalFailure('Too many requests. Please try again in a moment.');
        }
        if (response2.statusCode == 402) {
          return AskLocalFailure('AI service credits exhausted. Please try again later.');
        }
        // Use server error message when present (e.g. 500 with { "error": "..." })
        String message = 'Something went wrong. Please try again.';
        try {
          final map = jsonDecode(resBody) as Map<String, dynamic>?;
          final err = map?['error'] as String?;
          if (err != null && err.isNotEmpty) message = err;
        } catch (_) {}
        return AskLocalFailure(message);
      }

      final lineStream = LineSplitter().bind(
        response2.stream.transform(utf8.decoder),
      );
      final stream = lineStream.asyncExpand<String>((line) async* {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) return;
        final payload = trimmed.substring(6).trim();
        if (payload == '[DONE]') return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>?;
          final choices = map?['choices'];
          if (choices is! List || choices.isEmpty) return;
          final first = choices[0];
          if (first is! Map<String, dynamic>) return;
          final delta = first['delta'];
          if (delta is! Map<String, dynamic>) return;
          final content = delta['content'];
          if (content is String && content.isNotEmpty) yield content;
        } catch (_) {}
      });

      return AskLocalStream(stream);
    } catch (e) {
      return AskLocalFailure('Something went wrong. Please try again.');
    }
  }
}
