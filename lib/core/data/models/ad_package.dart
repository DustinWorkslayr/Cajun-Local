/// Schema-aligned model for `ad_packages` (pricing-and-ads-cheatsheet §2.5).
/// Public SELECT; admin-only write.
library;

class AdPackage {
  const AdPackage({
    required this.id,
    required this.name,
    required this.placement,
    required this.durationDays,
    required this.price,
    this.maxImpressions,
    this.description,
    this.stripePriceId,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  /// One of: directory_top, category_banner, search_results, deal_spotlight, homepage_featured
  final String placement;
  final int durationDays;
  final double price;
  final int? maxImpressions;
  final String? description;
  final String? stripePriceId;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdPackage.fromJson(Map<String, dynamic> json) {
    return AdPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      placement: json['placement'] as String,
      durationDays: json['duration_days'] as int? ?? 0,
      price: _toDouble(json['price']),
      maxImpressions: json['max_impressions'] as int?,
      description: json['description'] as String?,
      stripePriceId: json['stripe_price_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'placement': placement,
        'duration_days': durationDays,
        'price': price,
        'max_impressions': maxImpressions,
        'description': description,
        'stripe_price_id': stripePriceId,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  static String placementLabel(String placement) {
    switch (placement) {
      case 'directory_top':
        return 'Directory top';
      case 'category_banner':
        return 'Category banner';
      case 'search_results':
        return 'Search results';
      case 'deal_spotlight':
        return 'Deal spotlight';
      case 'homepage_featured':
        return 'Homepage featured';
      default:
        return placement;
    }
  }

  /// Short explanation of where the ad appears and what it does (for Buy ad screen).
  static String placementDescription(String placement) {
    switch (placement) {
      case 'directory_top':
        return 'Your ad appears at the top of the Explore directory so users see you first when browsing local businesses.';
      case 'category_banner':
        return 'A sponsored banner in Explore highlights your category. Great for reaching people exploring a specific type of business (e.g. restaurants, music).';
      case 'search_results':
        return 'Your business is promoted within search results in the app, so you show up when locals search for what you offer.';
      case 'deal_spotlight':
        return 'Your deal gets featured in the Deals tab so members looking for offers discover you.';
      case 'homepage_featured':
        return 'Your business is featured on the home screen where members land when they open the app.';
      default:
        return 'Sponsored placement in the app.';
    }
  }
}
