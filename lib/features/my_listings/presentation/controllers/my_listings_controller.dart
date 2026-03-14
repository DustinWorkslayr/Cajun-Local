import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';

part 'my_listings_controller.g.dart';

@riverpod
class MyListingsController extends _$MyListingsController {
  @override
  FutureOr<List<Business>> build() async {
    return _fetchListings();
  }

  Future<List<Business>> _fetchListings() async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null) return [];

    final businessIds = await BusinessManagersRepository().listBusinessIdsForUser(userId);
    final results = await Future.wait(
      businessIds.map((id) => BusinessRepository().getById(id)),
    );
    return results.whereType<Business>().toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchListings());
  }
}
