import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/favorites/data/api/favorites_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_repository.g.dart';

/// Favorites (backend-cheatsheet §1).
class FavoritesRepository {
  FavoritesRepository({FavoritesApi? api}) : _api = api ?? FavoritesApi(ApiClient.instance);

  final FavoritesApi _api;

  /// List business IDs favorited by the current user. Returns [] when not signed in.
  Future<List<String>> list() async {
    try {
      final list = await _api.listFavorites();
      return list.map((e) => e['business_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a favorite for the current user.
  Future<void> add(String businessId) async {
    await _api.addFavorite(businessId);
  }

  /// Remove a favorite for the current user.
  Future<void> remove(String businessId) async {
    await _api.removeFavorite(businessId);
  }

  /// Total number of users who favorited this business.
  Future<int> getCountForBusiness(String businessId) async {
    try {
      return await _api.getFavoriteCount(businessId);
    } catch (_) {
      return 0;
    }
  }

  /// Favorites count per business.
  Future<Map<String, int>> getCountsForBusinesses(List<String> businessIds) async {
    if (businessIds.isEmpty) return {};
    try {
      return await _api.getBulkFavoriteCounts(businessIds);
    } catch (_) {
      return {};
    }
  }
}

@riverpod
FavoritesRepository favoritesRepository(FavoritesRepositoryRef ref) {
  return FavoritesRepository(api: ref.watch(favoritesApiProvider));
}
