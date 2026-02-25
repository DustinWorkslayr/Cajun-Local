import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Blog posts with moderation (backend-cheatsheet §2). Admin can list any status and update.
class BlogPostsRepository {
  BlogPostsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  static const _limit = 500;

  /// Public: list approved/published posts for News (backend-cheatsheet §7).
  Future<List<BlogPost>> listApproved({int limit = 50}) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('blog_posts')
        .select()
        .eq('status', 'approved')
        .order('published_at', ascending: false)
        .limit(limit);
    return (list as List).map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BlogPost>> listForAdmin({String? status}) async {
    final client = _client;
    if (client == null) return [];
    var q = client.from('blog_posts').select();
    if (status != null) q = q.eq('status', status);
    final list = await q.order('created_at', ascending: false).limit(_limit);
    return (list as List).map((e) => BlogPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BlogPost?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('blog_posts').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return BlogPost.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStatus(String id, String status, {String? approvedBy}) async {
    final client = _client;
    if (client == null) return;
    final data = <String, dynamic>{'status': status};
    if (status == 'approved') {
      data['published_at'] = DateTime.now().toUtc().toIso8601String();
    }
    await client.from('blog_posts').update(data).eq('id', id);
  }

  /// Admin: create a new blog post (status defaults to draft).
  Future<void> insert({
    required String title,
    required String slug,
    String? content,
    String? excerpt,
    String status = 'draft',
    String? authorId,
    String? coverImageUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    final id = 'bp-${DateTime.now().millisecondsSinceEpoch}-${slug.hashCode.abs()}';
    await client.from('blog_posts').insert({
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'status': status,
      ...? (authorId != null ? {'author_id': authorId} : null),
      ...? (coverImageUrl != null ? {'cover_image_url': coverImageUrl} : null),
    });
  }

  /// Admin: update an existing blog post (title, slug, content, excerpt, status, cover).
  Future<void> update({
    required String id,
    required String title,
    required String slug,
    String? content,
    String? excerpt,
    required String status,
    String? coverImageUrl,
  }) async {
    final client = _client;
    if (client == null) return;
    await client.from('blog_posts').update({
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'status': status,
      'cover_image_url': coverImageUrl,
    }).eq('id', id);
  }
}
