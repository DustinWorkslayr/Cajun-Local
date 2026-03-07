import 'package:dio/dio.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/preferences/auth_preferences.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.authRepository, required this.dio});

  final AuthRepository authRepository;
  final Dio dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthPreferences.getToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final newToken = await authRepository.getRefreshToken();

      if (newToken != null) {
        await AuthPreferences.setToken(newToken);

        final request = err.requestOptions;
        request.headers['Authorization'] = 'Bearer $newToken';

        final response = await dio.fetch(request);

        return handler.resolve(response);
      }
    }

    handler.next(err);
  }
}
