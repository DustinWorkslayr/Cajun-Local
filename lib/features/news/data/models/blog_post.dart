import 'package:freezed_annotation/freezed_annotation.dart';

part 'blog_post.freezed.dart';
part 'blog_post.g.dart';

@freezed
abstract class BlogPost with _$BlogPost {
  const BlogPost._();

  const factory BlogPost({
    required String id,
    required String slug,
    required String title,
    required String status,
    String? content,
    String? excerpt,
    @JsonKey(name: 'author_id') String? authorId,
    @JsonKey(name: 'cover_image_url') String? coverImageUrl,
    @JsonKey(name: 'parish_ids') List<String>? parishIds,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _BlogPost;

  bool get isAllParishes => parishIds == null || parishIds!.isEmpty;

  factory BlogPost.fromJson(Map<String, dynamic> json) => _$BlogPostFromJson(json);
}
