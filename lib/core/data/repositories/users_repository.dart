import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/users_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_repository.g.dart';

class UsersRepository {
  UsersRepository({UsersApi? api}) : _api = api ?? UsersApi(ApiClient.instance);
  final UsersApi _api;

  Future<void> removeUserFromApp(String userId) async {
    await _api.deleteUser(userId);
  }
}

@riverpod
UsersRepository usersRepository(UsersRepositoryRef ref) {
  return UsersRepository(api: ref.watch(usersApiProvider));
}
