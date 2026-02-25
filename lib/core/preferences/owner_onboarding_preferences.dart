import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has completed first-time business owner onboarding
/// (welcome + plan choice). Used to show owner onboarding dialog once.
class OwnerOnboardingPreferences {
  OwnerOnboardingPreferences._();

  static const String _keyCompletedOwnerOnboarding = 'completed_owner_onboarding';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<bool> hasCompletedOwnerOnboarding() async {
    final prefs = await _instance;
    return prefs.getBool(_keyCompletedOwnerOnboarding) ?? false;
  }

  static Future<void> setCompletedOwnerOnboarding() async {
    final prefs = await _instance;
    await prefs.setBool(_keyCompletedOwnerOnboarding, true);
  }
}
