import 'dart:typed_data';

import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads images to the `business-images` bucket and returns public URLs.
/// Paths: `{businessId}/gallery/{uniqueId}.{ext}`, or for logo/banner either
/// owner: `{businessId}/logo.{ext}` / `{businessId}/banner.{ext}` or
/// admin: `{businessId}/admin/logo.{ext}` / `{businessId}/admin/banner.{ext}`.
class BusinessImagesStorageService {
  BusinessImagesStorageService();

  static const String _bucket = 'business-images';

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Upload image bytes to the bucket. Returns the public URL for the file.
  /// [businessId] – business the image belongs to.
  /// [type] – 'gallery' for gallery images, 'logo' for business logo, 'banner' for listing banner/cover.
  /// [bytes] – image file bytes.
  /// [extension] – e.g. 'jpg', 'png' (allowed: jpg, jpeg, png, gif, webp; max 5 MB).
  /// [isAdminUpload] – if true, logo/banner are stored under `{businessId}/admin/` so they are
  ///   distinct from business-owner uploads (owner uses `{businessId}/logo.{ext}` etc.).
  Future<String> upload({
    required String businessId,
    required String type,
    required Uint8List bytes,
    required String extension,
    bool isAdminUpload = false,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';
    final String path;
    if (type == 'logo') {
      path = isAdminUpload ? '$businessId/admin/logo.$safeExt' : '$businessId/logo.$safeExt';
    } else if (type == 'banner') {
      path = isAdminUpload ? '$businessId/admin/banner.$safeExt' : '$businessId/banner.$safeExt';
    } else {
      path = '$businessId/gallery/${DateTime.now().millisecondsSinceEpoch}-${bytes.hashCode.abs()}.$safeExt';
    }

    final contentType = _contentTypeForExtension(safeExt);
    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return client.storage.from(_bucket).getPublicUrl(path);
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
