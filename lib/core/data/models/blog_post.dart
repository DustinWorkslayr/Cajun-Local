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
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      content: json['content'] as String?,
      excerpt: json['excerpt'] as String?,
      authorId: json['author_id'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
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
