import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode
        ? 'https://api.cajunlocal.com/api/v1'
        : 'http://localhost:8000/api/v1',
  );
}
