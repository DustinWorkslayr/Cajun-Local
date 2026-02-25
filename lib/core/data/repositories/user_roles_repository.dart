import 'package:my_app/core/data/models/user_role.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User roles (backend-cheatsheet §2). RLS: user can SELECT own; admin for write.
/// [user_id] must be a Supabase auth UUID; non-UUID values (e.g. subscription ids)
/// cause Postgres "invalid input syntax for type uuid" (22P02).
class UserRolesRepository {
  UserRolesRepository();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isValidUserId(String userId) => _uuidRegex.hasMatch(userId);

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Current user can read own role from user_roles.
  Future<String?> getRoleForUser(String userId) async {
    final client = _client;
    if (client == null) return null;
    if (!isValidUserId(userId)) return null;
    final res = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return res['role'] as String?;
  }

  /// Admin: list all user roles.
  Future<List<UserRole>> listForAdmin() async {
    final client = _client;
    if (client == null) return [];
    final list = await client.from('user_roles').select().order('user_id');
    return (list as List).map((e) => UserRole.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin: set role for user (update existing row or insert if none).
  /// Throws [ArgumentError] if [userId] is not a valid UUID (avoids PostgrestException 22P02).
  Future<void> setRole(String userId, String role) async {
    if (!isValidUserId(userId)) {
      throw ArgumentError(
        'user_id must be a Supabase auth UUID. Got invalid id (e.g. legacy or wrong table id). '
        'Fix the row in Supabase Dashboard (Table Editor > user_roles) or remove it.',
      );
    }
    final client = _client;
    if (client == null) return;
    final rows = await client.from('user_roles').select('user_id').eq('user_id', userId);
    final list = rows as List;
    if (list.isNotEmpty) {
      await client.from('user_roles').update({'role': role}).eq('user_id', userId);
    } else {
      await client.from('user_roles').insert({'user_id': userId, 'role': role});
    }
  }

  /// Admin: remove role row for user.
  Future<void> deleteRole(String userId) async {
    if (!isValidUserId(userId)) return;
    final client = _client;
    if (client == null) return;
    await client.from('user_roles').delete().eq('user_id', userId);
  }
}
