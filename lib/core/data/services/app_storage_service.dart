import 'dart:typed_data';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/admin/data/api/uploads_api.dart';
import 'package:cajun_local/core/data/services/storage_upload_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_storage_service.g.dart';

/// Central storage for all app buckets (backend-cheatsheet §12).
class AppStorageService {
  AppStorageService({UploadsApi? api}) : _api = api ?? UploadsApi(ApiClient.instance);
  final UploadsApi _api;

  static const String bucketAvatars = 'avatars';
  static const String bucketBusinessImages = 'business-images';
  static const String bucketAdImages = 'ad-images';
  static const String bucketEventImages = 'event-images';
  static const String bucketMenuImages = 'menu-images';
  static const String bucketBlogImages = 'blog-images';
  static const String bucketCategoryBanners = 'category-banners';

  /// avatars/{user_id}/{filename} — profiles.avatar_url. Own user only.
  Future<String> uploadAvatar({required String userId, required Uint8List bytes, required String extension}) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: 'avatar.$safeExt', mimeType: mimeType, folder: bucketAvatars);
  }

  /// business-images/{business_id}/{filename} — businesses.logo, businesses.banner, business_images.
  Future<String> uploadBusinessImage({
    required String businessId,
    required String type,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: '$type.$safeExt', mimeType: mimeType, folder: bucketBusinessImages);
  }

  /// ad-images/{business_id}/{filename} — business_ads.image_url.
  Future<String> uploadAdImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: 'ad.$safeExt', mimeType: mimeType, folder: bucketAdImages);
  }

  /// event-images/{business_id}/{filename} — business_events.image_url.
  Future<String> uploadEventImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: 'event.$safeExt', mimeType: mimeType, folder: bucketEventImages);
  }

  /// menu-images/{business_id}/{filename} — menu_items.image_url.
  Future<String> uploadMenuImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: 'menu.$safeExt', mimeType: mimeType, folder: bucketMenuImages);
  }

  /// blog-images/{any}/{filename} — blog_posts.cover_image_url. Admin only.
  Future<String> uploadBlogImage({
    required String pathSegment,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(bytes: bytes, filename: 'blog.$safeExt', mimeType: mimeType, folder: bucketBlogImages);
  }

  /// category-banners/{any}/{filename} — category_banners.image_url. Admin only.
  Future<String> uploadCategoryBanner({
    required String pathSegment,
    required Uint8List bytes,
    required String extension,
  }) async {
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final mimeType = _contentTypeForExtension(safeExt);
    return _api.uploadImage(
      bytes: bytes,
      filename: 'banner.$safeExt',
      mimeType: mimeType,
      folder: bucketCategoryBanners,
    );
  }
}

String _contentTypeForExtension(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

@riverpod
AppStorageService appStorageService(AppStorageServiceRef ref) {
  return AppStorageService(api: ref.watch(uploadsApiProvider));
}
