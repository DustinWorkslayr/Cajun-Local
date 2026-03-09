import 'package:dio/dio.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/token_storage.dart';
import 'package:my_app/core/auth/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Call FastAPI login endpoint
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {'email': email, 'password': password});

      // Save tokens securely
      await TokenStorage.saveTokens(
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );

      return _fetchMe();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Failed to sign in';
      throw Exception(detail);
    }
  }

  /// Call FastAPI register endpoint
  Future<UserModel> signUp({required String email, required String password, String? displayName}) async {
    try {
      await _client.dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'display_name': displayName},
      );

      // Auto-login after successful registration
      return signIn(email: email, password: password);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Failed to sign up';
      throw Exception(detail);
    }
  }

  /// Fetch the current user profile from `/auth/me`
  Future<UserModel> _fetchMe() async {
    try {
      final response = await _client.dio.get('/auth/me');
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if session exists on startup and load user
  Future<UserModel?> initializeSession() async {
    if (!await TokenStorage.hasToken()) return null;

    try {
      return await _fetchMe();
    } catch (_) {
      // Token is invalid/expired completely. Cleanup.
      await TokenStorage.clearTokens();
      return null;
    }
  }

  Future<void> signOut() async {
    await TokenStorage.clearTokens();
  }

  /// Recover password flow
  Future<void> recoverPassword(String email) async {
    await _client.dio.post('/auth/recover-password', data: {'email': email});
  }

  /// Reset password flow
  Future<void> resetPassword(String token, String newPassword) async {
    await _client.dio.post('/auth/reset-password', data: {'token': token, 'new_password': newPassword});
  }

  /// Change password while logged in
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.dio.post(
      '/auth/change-password',
      queryParameters: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  /// Update current user profile
  Future<UserModel> updateProfile({String? displayName, String? avatarUrl}) async {
    await _client.dio.put(
      '/profiles/me',
      queryParameters: {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    return _fetchMe(); // Refresh user model
  }

  /// Sign in with Google ID token
  Future<UserModel> signInWithGoogle(String idToken) async {
    try {
      final response = await _client.dio.post('/auth/google-login', data: {'id_token': idToken});

      await TokenStorage.saveTokens(
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );

      return _fetchMe();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Failed to sign in with Google';
      throw Exception(detail);
    }
  }
}

@riverpod
AuthApi authApi(AuthApiRef ref) {
  return AuthApi(ApiClient.instance);
}
