/// Schema-aligned model for `blog_posts` (backend-cheatsheet §1).
library;

class BlogPost {
  const BlogPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.status,
    this.content,
    this.excerpt,
    this.authorId,
    this.coverImageUrl,
    this.parishIds,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String status;
  final String? content;
  final String? excerpt;
  final String? authorId;
  final String? coverImageUrl;
  /// When null or empty, post is shown to all parishes. Otherwise only to users whose preferred parish is in this list.
  final List<String>? parishIds;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True if this post is visible to all parishes (no parish restriction).
  bool get isAllParishes =>
      parishIds == null || parishIds!.isEmpty;

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    List<String>? parishIds;
    final raw = json['parish_ids'];
    if (raw is List) {
      parishIds = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      if (parishIds.isEmpty) parishIds = null;
    }
    return BlogPost(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      content: (json['content'] as String?) ?? (json['body'] as String?),
      excerpt: json['excerpt'] as String?,
      authorId: json['author_id'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      parishIds: parishIds,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
