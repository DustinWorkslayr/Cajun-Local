import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/repositories/user_roles_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth and profile access. Uses Supabase Auth when configured.
/// Profiles: RLS allows own row only (backend-cheatsheet §2).
class AuthRepository {
  AuthRepository({UserRolesRepository? userRolesRepository})
      : _userRoles = userRolesRepository ?? UserRolesRepository();

  final UserRolesRepository _userRoles;

  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Current session if signed in.
  Session? get currentSession => _client?.auth.currentSession;

  /// Current user id (null if not signed in).
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Stream of auth state changes (session added/removed).
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Redirect URL for email confirmation link (deep link). Add to Supabase
  /// Dashboard → Auth → URL Configuration → Redirect URLs (e.g. cajunlocal://auth/confirm/**).
  static const String _emailConfirmRedirectUrl = 'cajunlocal://auth/confirm/';

  /// Sign up with email and password. Confirmation email is sent by Supabase Auth
  /// using your project's custom SMTP. Trigger creates profile + user role (§9).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
      emailRedirectTo: kIsWeb ? null : _emailConfirmRedirectUrl,
    );
    return res;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Send a password reset email. User must open the link in the same device
  /// (or use the same redirect URL) so the app can receive the deep link.
  Future<void> resetPasswordForEmail(String email) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : _passwordResetRedirectUrl,
    );
  }

  /// Redirect URL for password reset deep link. Add this to Supabase Dashboard
  /// Auth → URL Configuration → Redirect URLs (e.g. cajunlocal://reset-password/**).
  static const String _passwordResetRedirectUrl =
      'cajunlocal://reset-password/';

  /// Update the current user's password (e.g. after opening the reset link).
  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out.
  Future<void> signOut() async {
    final client = _client;
    if (client != null) await client.auth.signOut();
  }

  /// Current user's role from `user_roles` (RLS: own SELECT). Null if not signed in.
  Future<String?> getCurrentUserRole() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _userRoles.getRoleForUser(uid);
  }

  /// True when signed in and role is admin or super_admin (both have full admin access).
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'super_admin';
  }

  /// Load the current user's profile from `profiles` (RLS: own only).
  /// Returns null if not signed in or profile not found.
  Future<Profile?> getCurrentProfile() async {
    final client = _client;
    final uid = currentUserId;
    if (client == null || uid == null) return null;
    final res = await client
        .from('profiles')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: get a single profile by user id. Returns null if not found.
  Future<Profile?> getProfileForAdmin(String userId) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('profiles').select().eq('user_id', userId).maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(res));
  }

  /// Admin: list all profiles (RLS: admin can SELECT all).
  Future<List<Profile>> listProfilesForAdmin() async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('profiles').select().order('user_id');
    return (list as List).map((e) => Profile.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Update the current user's own profile (e.g. avatar_url). RLS must allow own-row UPDATE.
  Future<void> updateOwnProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final client = _client;
    final uid = currentUserId;
    if (client == null || uid == null) return;
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (data.isEmpty) return;
    await client.from('profiles').update(data).eq('user_id', uid);
  }

  /// Admin: update a user's profile (e.g. display_name, avatar_url). RLS: admin can UPDATE.
  Future<void> updateProfileForAdmin(
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (data.isEmpty) return;
    await client.from('profiles').update(data).eq('user_id', userId);
  }

  /// Admin: remove user from app (profile, role, subscription). Does not delete from auth.users;
  /// use Supabase Dashboard > Authentication > Users for full removal.
  Future<void> removeUserFromApp(String userId) async {
    final client = _client;
    if (client == null) return;
    await client.from('user_subscriptions').delete().eq('user_id', userId);
    await client.from('user_roles').delete().eq('user_id', userId);
    await client.from('profiles').delete().eq('user_id', userId);
  }
}
