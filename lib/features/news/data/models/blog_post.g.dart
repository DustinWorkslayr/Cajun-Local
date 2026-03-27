// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BlogPost _$BlogPostFromJson(Map<String, dynamic> json) => _BlogPost(
  id: json['id'] as String,
  slug: json['slug'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  content: json['content'] as String?,
  excerpt: json['excerpt'] as String?,
  authorId: json['author_id'] as String?,
  coverImageUrl: json['cover_image_url'] as String?,
  parishIds: (json['parish_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BlogPostToJson(_BlogPost instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'status': instance.status,
  'content': instance.content,
  'excerpt': instance.excerpt,
  'author_id': instance.authorId,
  'cover_image_url': instance.coverImageUrl,
  'parish_ids': instance.parishIds,
  'published_at': instance.publishedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
