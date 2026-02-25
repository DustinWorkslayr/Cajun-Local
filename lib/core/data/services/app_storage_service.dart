import 'dart:typed_data';

import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central storage for all app buckets (backend-cheatsheet §12).
/// Path conventions: avatars/{user_id}/{filename}, business-images/{business_id}/{filename},
/// ad-images/{business_id}/{filename}, event-images/{business_id}/{filename},
/// menu-images/{business_id}/{filename}, blog-images/{any}/{filename},
/// category-banners/{any}/{filename}.
/// All buckets are public for read; RLS on storage.objects scopes upload/delete.
class AppStorageService {
  AppStorageService();

  static const String bucketAvatars = 'avatars';
  static const String bucketBusinessImages = 'business-images';
  static const String bucketAdImages = 'ad-images';
  static const String bucketEventImages = 'event-images';
  static const String bucketMenuImages = 'menu-images';
  static const String bucketBlogImages = 'blog-images';
  static const String bucketCategoryBanners = 'category-banners';

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Upload bytes to a bucket and return the public URL.
  /// Restricts to allowed image types and max size (see [storage_upload_constants]).
  Future<String> _upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String extension,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final fullPath = path.endsWith('.$safeExt') ? path : '$path.$safeExt';
    final contentType = _contentTypeForExtension(safeExt);
    await client.storage.from(bucket).uploadBinary(
          fullPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return client.storage.from(bucket).getPublicUrl(fullPath);
  }

  /// avatars/{user_id}/{filename} — profiles.avatar_url. Own user only.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketAvatars,
      path: '$userId/$name',
      bytes: bytes,
      extension: extension,
    );
  }

  /// business-images/{business_id}/{filename} — businesses.logo, businesses.banner, business_images.
  /// [type] 'logo' -> {id}/logo, 'banner' -> {id}/banner, else -> {id}/gallery/{unique}
  Future<String> uploadBusinessImage({
    required String businessId,
    required String type,
    required Uint8List bytes,
    required String extension,
  }) async {
    final String path;
    if (type == 'logo') {
      path = '$businessId/logo';
    } else if (type == 'banner') {
      path = '$businessId/banner';
    } else {
      path = '$businessId/gallery/${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    }
    return _upload(bucket: bucketBusinessImages, path: path, bytes: bytes, extension: extension);
  }

  /// ad-images/{business_id}/{filename} — business_ads.image_url.
  Future<String> uploadAdImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketAdImages,
      path: '$businessId/$name',
      bytes: bytes,
      extension: extension,
    );
  }

  /// event-images/{business_id}/{filename} — business_events.image_url.
  Future<String> uploadEventImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketEventImages,
      path: '$businessId/$name',
      bytes: bytes,
      extension: extension,
    );
  }

  /// menu-images/{business_id}/{filename} — menu_items.image_url.
  Future<String> uploadMenuImage({
    required String businessId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketMenuImages,
      path: '$businessId/$name',
      bytes: bytes,
      extension: extension,
    );
  }

  /// blog-images/{any}/{filename} — blog_posts.cover_image_url. Admin only.
  Future<String> uploadBlogImage({
    required String pathSegment,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketBlogImages,
      path: '$pathSegment/$name',
      bytes: bytes,
      extension: extension,
    );
  }

  /// category-banners/{any}/{filename} — category_banners.image_url. Admin only.
  Future<String> uploadCategoryBanner({
    required String pathSegment,
    required Uint8List bytes,
    required String extension,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}';
    return _upload(
      bucket: bucketCategoryBanners,
      path: '$pathSegment/$name',
      bytes: bytes,
      extension: extension,
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
