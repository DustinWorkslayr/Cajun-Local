import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/core/data/listing_data_source.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';

part 'favorites_providers.g.dart';

@riverpod
class UserFavoriteIds extends _$UserFavoriteIds {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return {};
    
    final repo = ref.watch(favoritesRepositoryProvider);
    final list = await repo.list();
    return list.toSet();
  }

  Future<void> add(String businessId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    await repo.add(businessId);
    
    final currentIds = await future;
    state = AsyncData({...currentIds, businessId});
  }

  Future<void> remove(String businessId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    await repo.remove(businessId);
    
    final currentIds = await future;
    state = AsyncData(currentIds.where((id) => id != businessId).toSet());
  }
  
  Future<void> toggle(String businessId) async {
    final currentIds = state.valueOrNull ?? {};
    if (currentIds.contains(businessId)) {
      await remove(businessId);
    } else {
      await add(businessId);
    }
  }
}

@riverpod
Future<List<MockListing>> favoriteListings(Ref ref) async {
  final idsAsync = ref.watch(userFavoriteIdsProvider);
  final ids = idsAsync.valueOrNull ?? {};
  
  if (ids.isEmpty) return [];
  
  final ds = ref.watch(listingDataSourceProvider);
  
  // Fetch in batches if there are many, or just Future.wait for smaller sets.
  // For favorites, usually it's not hundreds.
  final results = await Future.wait(ids.map((id) => ds.getListingById(id)));
  return results.whereType<MockListing>().toList();
}
