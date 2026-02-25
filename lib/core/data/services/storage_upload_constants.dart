/// Allowed file types and size limits for storage uploads (security & storage usage).
/// Use for image buckets only; other flows (e.g. CSV import) define their own rules.
library;

/// Allowed image extensions for avatars, business-images, ad-images, event-images,
/// menu-images, blog-images, category-banners. No dot; lowercase.
const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// Max size per image upload (5 MB) to limit storage and abuse.
const int maxImageBytes = 5 * 1024 * 1024;

/// Normalizes extension (lowercase, no leading dot). Returns null if not allowed.
String? normalizeAllowedImageExtension(String? extension) {
  if (extension == null || extension.trim().isEmpty) return null;
  final ext = extension.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
  return allowedImageExtensions.contains(ext) ? ext : null;
}

/// Validates image bytes and extension. Throws [FormatException] if invalid.
void validateImageUpload(List<int> bytes, String? extension) {
  final ext = normalizeAllowedImageExtension(extension);
  if (ext == null) {
    throw FormatException(
      'Invalid image type. Allowed: ${allowedImageExtensions.join(", ")}',
    );
  }
  if (bytes.length > maxImageBytes) {
    final mb = (maxImageBytes / (1024 * 1024)).toStringAsFixed(0);
    throw FormatException(
      'Image too large. Maximum size is $mb MB.',
    );
  }
}
