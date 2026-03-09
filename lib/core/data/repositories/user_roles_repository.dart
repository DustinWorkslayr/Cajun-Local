import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/user_roles_api.dart';
import 'package:my_app/core/data/models/user_role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_roles_repository.g.dart';

/// User roles (backend-cheatsheet §2). RLS: user can SELECT own; admin for write.
class UserRolesRepository {
  UserRolesRepository({UserRolesApi? api}) : _api = api ?? UserRolesApi(ApiClient.instance);
  final UserRolesApi _api;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isValidUserId(String userId) => _uuidRegex.hasMatch(userId);

  /// Current user can read own role.
  Future<String?> getRoleForUser(String userId) async {
    if (!isValidUserId(userId)) return null;
    return _api.getRoleForUser(userId);
  }

  /// Admin: list all user roles.
  Future<List<UserRole>> listForAdmin() async {
    return _api.listForAdmin();
  }

  /// Admin: set role for user (update existing row or insert if none).
  /// Throws [ArgumentError] if [userId] is not a valid UUID.
  Future<void> setRole(String userId, String role) async {
    if (!isValidUserId(userId)) {
      throw ArgumentError('user_id must be a valid UUID.');
    }
    await _api.setRole(userId, role);
  }

  /// Admin: remove role row for user.
  Future<void> deleteRole(String userId) async {
    if (!isValidUserId(userId)) return;
    await _api.deleteRole(userId);
  }
}

@riverpod
UserRolesRepository userRolesRepository(UserRolesRepositoryRef ref) {
  return UserRolesRepository(api: ref.watch(userRolesApiProvider));
}
