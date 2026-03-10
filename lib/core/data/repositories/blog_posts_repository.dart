import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/blog_posts_api.dart';
import 'package:cajun_local/core/data/models/blog_post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blog_posts_repository.g.dart';

/// Blog posts with moderation (backend-cheatsheet §2). Admin can list any status and update.
class BlogPostsRepository {
  BlogPostsRepository({BlogPostsApi? api}) : _api = api ?? BlogPostsApi(ApiClient.instance);

  final BlogPostsApi _api;

  static const _limit = 500;

  /// Public: list approved/published posts for News (backend-cheatsheet §7).
  Future<List<BlogPost>> listApproved({int limit = 50, Set<String>? forParishIds}) async {
    final list = await _api.listPosts(
      statuses: ['approved', 'published'],
      parishIds: forParishIds?.toList(),
      limit: limit,
    );
    return list.map((e) => BlogPost.fromJson(e)).toList();
  }

  Future<List<BlogPost>> listForAdmin({String? status}) async {
    final list = await _api.listPosts(statuses: status != null ? [status] : null, limit: _limit);
    return list.map((e) => BlogPost.fromJson(e)).toList();
  }

  Future<BlogPost?> getById(String id) async {
    try {
      final res = await _api.getPostById(id);
      return BlogPost.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    await _api.updatePost(id, {'status': status});
  }

  /// Admin: create a new blog post.
  Future<void> insert({
    required String title,
    required String slug,
    String? content,
    String? excerpt,
    String status = 'draft',
    String? authorId,
    String? coverImageUrl,
    List<String>? parishIds,
  }) async {
    await _api.createPost({
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'status': status,
      if (authorId != null) 'author_id': authorId,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      'parish_ids': parishIds ?? [],
    });
  }

  /// Admin: update an existing blog post.
  Future<void> update({
    required String id,
    required String title,
    required String slug,
    String? content,
    String? excerpt,
    required String status,
    String? coverImageUrl,
    List<String>? parishIds,
  }) async {
    await _api.updatePost(id, {
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'status': status,
      'cover_image_url': coverImageUrl,
      'parish_ids': parishIds ?? [],
    });
  }
}

@riverpod
BlogPostsRepository blogPostsRepository(BlogPostsRepositoryRef ref) {
  return BlogPostsRepository(api: ref.watch(blogPostsApiProvider));
}
