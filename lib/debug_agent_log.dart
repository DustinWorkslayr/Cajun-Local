import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

// #region agent log
void agentLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  final payload = jsonEncode({
    'sessionId': 'c3074d',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'data': data,
    'hypothesisId': hypothesisId,
  });
  debugPrint('[agentLog] $payload');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    http
        .post(
          Uri.parse('http://127.0.0.1:7502/ingest/58e774ec-c055-4d4c-9003-6629b1f7380e'),
          headers: {'Content-Type': 'application/json', 'X-Debug-Session-Id': 'c3074d'},
          body: payload,
        )
        .catchError((_) => Future.value(http.Response('', 500)));
  });
}
// #endregion
