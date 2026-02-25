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
  AskLocalService();

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
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    final body = <String, dynamic>{'question': question.trim()};
    if (preferredParishIds != null && preferredParishIds.isNotEmpty) {
      body['preferred_parish_ids'] = preferredParishIds;
    }
    request.body = jsonEncode(body);

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 403) {
        String body = '';
        await for (final chunk in response.stream) {
          body += utf8.decode(chunk);
        }
        client.close();
        String? code;
        String message = 'Access denied.';
        try {
          final map = jsonDecode(body) as Map<String, dynamic>?;
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

      if (response.statusCode == 400) {
        String body = '';
        await for (final chunk in response.stream) {
          body += utf8.decode(chunk);
        }
        client.close();
        try {
          final map = jsonDecode(body) as Map<String, dynamic>?;
          final err = map?['error'] as String?;
          if (err != null && err.isNotEmpty) {
            return AskLocalFailure(err);
          }
        } catch (_) {}
        return AskLocalFailure('A question is required.');
      }

      if (response.statusCode != 200) {
        await response.stream.drain();
        client.close();
        if (response.statusCode == 429) {
          return AskLocalFailure('Too many requests. Please try again in a moment.');
        }
        if (response.statusCode == 402) {
          return AskLocalFailure('AI service credits exhausted. Please try again later.');
        }
        return AskLocalFailure('Something went wrong. Please try again.');
      }

      final lineStream = LineSplitter().bind(
        response.stream.transform(utf8.decoder),
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
