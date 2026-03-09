import 'dart:typed_data';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/uploads_api.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';

/// Uploads images to the `business-images` bucket and returns public URLs.
/// Paths: `{businessId}/gallery/{uniqueId}.{ext}`, or for logo/banner either
/// owner: `{businessId}/logo.{ext}` / `{businessId}/banner.{ext}` or
/// admin: `{businessId}/admin/logo.{ext}` / `{businessId}/admin/banner.{ext}`.
class BusinessImagesStorageService {
  BusinessImagesStorageService({UploadsApi? api}) : _api = api ?? UploadsApi(ApiClient.instance);

  final UploadsApi _api;
  static const String _bucket = 'business-images';

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
    validateImageUpload(bytes, extension);
    final safeExt = normalizeAllowedImageExtension(extension) ?? 'jpg';

    // We don't strictly control the path on the backend with the current /storage/upload/image
    // but we can pass the folder or use a naming convention if needed.
    // For now, mirroring the folder structure via 'folder' query param.
    String folder = _bucket;
    if (type == 'logo') {
      folder = isAdminUpload ? '$_bucket/$businessId/admin' : '$_bucket/$businessId';
    } else if (type == 'banner') {
      folder = isAdminUpload ? '$_bucket/$businessId/admin' : '$_bucket/$businessId';
    } else {
      folder = '$_bucket/$businessId/gallery';
    }

    final filename = type == 'logo' ? 'logo.$safeExt' : (type == 'banner' ? 'banner.$safeExt' : 'image.$safeExt');
    final mimeType = _contentTypeForExtension(safeExt);

    return _api.uploadImage(bytes: bytes, filename: filename, mimeType: mimeType, folder: folder);
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
