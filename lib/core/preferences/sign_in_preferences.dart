import 'package:shared_preferences/shared_preferences.dart';

/// Remember-me and last-used email for the sign-in screen.
class SignInPreferences {
  SignInPreferences._();

  static const String _keyRememberMe = 'sign_in_remember_me';
  static const String _keyLastEmail = 'sign_in_last_email';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<bool> getRememberMe() async {
    final prefs = await _instance;
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_keyRememberMe, value);
  }

  static Future<String?> getLastEmail() async {
    final prefs = await _instance;
    return prefs.getString(_keyLastEmail);
  }

  static Future<void> setLastEmail(String? email) async {
    final prefs = await _instance;
    if (email == null || email.isEmpty) {
      await prefs.remove(_keyLastEmail);
    } else {
      await prefs.setString(_keyLastEmail, email);
    }
  }

  /// Clear saved email and remember-me (e.g. when user unchecks remember me).
  static Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyLastEmail);
  }
}
