import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists user's preferred parishes (for directory filters) and whether
/// they've completed the first-login parish onboarding.
class UserParishPreferences {
  UserParishPreferences._();

  static const String _keyPreferredParishIds = 'preferred_parish_ids';
  static const String _keyCompletedParishOnboarding = 'completed_parish_onboarding';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Preferred parish IDs (for filters). Empty if never set.
  static Future<Set<String>> getPreferredParishIds() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyPreferredParishIds);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list?.map((e) => e.toString()).toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> setPreferredParishIds(Set<String> ids) async {
    final prefs = await _instance;
    await prefs.setString(_keyPreferredParishIds, jsonEncode(ids.toList()));
  }

  static Future<bool> hasCompletedParishOnboarding() async {
    final prefs = await _instance;
    return prefs.getBool(_keyCompletedParishOnboarding) ?? false;
  }

  static Future<void> setCompletedParishOnboarding() async {
    final prefs = await _instance;
    await prefs.setBool(_keyCompletedParishOnboarding, true);
  }
}
