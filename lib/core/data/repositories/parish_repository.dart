import 'package:flutter/foundation.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/parish_api.dart';
import 'package:my_app/core/data/models/parish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parish_repository.g.dart';

/// Parishes table: allowed list for businesses and filters. Public read; admin write.
/// All parish lists in the app (Ask Local, filters, business forms, etc.) read from here — no mock fallback.
class ParishRepository {
  ParishRepository({ParishApi? api}) : _api = api ?? ParishApi(ApiClient.instance);

  final ParishApi _api;

  static const _limit = 500;

  /// Returns parishes from DB only. Empty if not configured or on error.
  Future<List<Parish>> listParishes() async {
    try {
      final list = await _api.listParishes(limit: _limit);
      return list.map((e) => Parish.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('ParishRepository.listParishes failed: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// Admin: create parish.
  Future<void> insertParish({required String id, required String name, int sortOrder = 0}) async {
    await _api.insertParish({'id': id, 'name': name, 'sort_order': sortOrder});
  }

  /// Admin: update parish.
  Future<void> updateParish(String id, {String? name, int? sortOrder}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    if (data.isEmpty) return;
    await _api.updateParish(id, data);
  }

  /// Admin: delete parish.
  Future<void> deleteParish(String id) async {
    await _api.deleteParish(id);
  }
}

@riverpod
ParishRepository parishRepository(ParishRepositoryRef ref) {
  return ParishRepository(api: ref.watch(parishApiProvider));
}
