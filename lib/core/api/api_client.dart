import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_config.dart';
import 'package:my_app/core/api/token_storage.dart';

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically inject the token into every request
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized (Token Expiration)
          if (e.response?.statusCode == 401) {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the failed request with the new token
                final newToken = await TokenStorage.getAccessToken();
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

                final response = await dio.request(
                  e.requestOptions.path,
                  options: Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                  ),
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              }
            } catch (_) {
              // If refresh fails, silently drop the session
              // The AuthRepository should be listening and log the user out
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio dio;

  /// Hit the refresh token endpoint and save new tokens.
  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    // Use a secondary Dio instance without interceptors to prevent infinite 401 loops
    final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    try {
      final response = await refreshDio.post(
        '/auth/refresh-token',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await TokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        return true;
      }
    } catch (_) {
      await TokenStorage.clearTokens();
    }
    return false;
  }
}
