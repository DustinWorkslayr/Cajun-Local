import 'package:shared_preferences/shared_preferences.dart';

/// Remember-me and last-used email for the sign-in screen.
class AuthPreferences {
  AuthPreferences._();

  static const String _userId = 'userId';
  static const String _token = 'token';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async => _prefs ??= await SharedPreferences.getInstance();

  static Future<String?> getUserId() async {
    final prefs = await _instance;
    return prefs.getString(_userId);
  }

  static Future<void> setUserId(String? value) async {
    final prefs = await _instance;
    if (value == null || value.isEmpty) {
      await prefs.remove(_userId);
    } else {
      await prefs.setString(_userId, value);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString(_token);
  }

  static Future<void> setToken(String? token) async {
    final prefs = await _instance;
    if (token == null || token.isEmpty) {
      await prefs.remove(_token);
    } else {
      await prefs.setString(_token, token);
    }
  }

  /// Clear saved email and remember-me (e.g. when user unchecks remember me).
  static Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_userId);
    await prefs.remove(_token);
  }
}
