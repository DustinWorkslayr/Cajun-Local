import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/favorites/data/repositories/favorites_repository.dart';
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
Future<List<Business>> favoriteListings(Ref ref) async {
  final idsAsync = ref.watch(userFavoriteIdsProvider);
  final ids = idsAsync.valueOrNull ?? {};
  
  if (ids.isEmpty) return [];
  
  final repo = BusinessRepository();
  
  final results = await Future.wait(ids.map((id) => repo.getById(id)));
  return results.whereType<Business>().toList();
}
