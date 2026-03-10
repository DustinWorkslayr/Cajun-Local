import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/notification_banners_api.dart';
import 'package:cajun_local/core/data/models/notification_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_banners_repository.g.dart';

class NotificationBannersRepository {
  NotificationBannersRepository({NotificationBannersApi? api})
    : _api = api ?? NotificationBannersApi(ApiClient.instance);
  final NotificationBannersApi _api;

  Future<List<NotificationBanner>> list() async {
    return _api.list();
  }

  /// Returns banners that are active and currently within their date window.
  Future<List<NotificationBanner>> listActive() async {
    final list = await _api.list(activeOnly: true);
    final now = DateTime.now();
    return list.where((b) {
      if (b.startDate != null && b.startDate!.isAfter(now)) return false;
      if (b.endDate != null && !b.endDate!.isAfter(now)) return false;
      return true;
    }).toList();
  }

  Future<NotificationBanner?> getById(String id) async {
    return _api.getById(id);
  }

  Future<void> insert(Map<String, dynamic> data) async {
    await _api.insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.update(id, data);
  }

  Future<void> delete(String id) async {
    await _api.delete(id);
  }
}

@riverpod
NotificationBannersRepository notificationBannersRepository(NotificationBannersRepositoryRef ref) {
  return NotificationBannersRepository(api: ref.watch(notificationBannersApiProvider));
}
