/// Schema-aligned model for `businesses` (backend-cheatsheet §1).
/// Public read: status = 'approved' only.
library;

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.status,
    required this.categoryId,
    this.slug,
    this.city,
    this.parish,
    this.state,
    this.latitude,
    this.longitude,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.tagline,
    this.logoUrl,
    this.bannerUrl,
    this.contactFormTemplate,
    this.createdAt,
    this.updatedAt,
    this.isClaimable,
  });

  final String id;
  final String name;
  final String status;
  final String categoryId;
  /// URL-safe slug (auto-generated from name; duplicates get -1, -2). Unique.
  final String? slug;
  final String? city;
  /// Parish id (e.g. 'lafayette') for directory filtering. Single primary parish.
  final String? parish;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? address;
  final String? phone;
  final String? website;
  final String? tagline;
  /// URL of business logo (stored in business-images bucket). DB column: logo_url.
  final String? logoUrl;
  /// URL of listing banner/cover image (hero). DB column: banner_url.
  final String? bannerUrl;
  /// One of: general_inquiry, appointment_request, quote_request, event_booking. Null = no form.
  final String? contactFormTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// True if no manager has claimed this business; false once claimed. Null if backend does not expose (no badge).
  final bool? isClaimable;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      categoryId: json['category_id'] as String,
      slug: json['slug'] as String?,
      city: json['city'] as String?,
      parish: json['parish'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      tagline: json['tagline'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['cover_image_url'] as String?,
      bannerUrl: json['banner_url'] as String? ?? json['cover_image_url'] as String?,
      contactFormTemplate: json['contact_form_template'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      isClaimable: json['is_claimable'] as bool?,
    );
  }
}
