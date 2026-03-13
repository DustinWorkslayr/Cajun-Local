import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';

part 'news_providers.g.dart';

@riverpod
Future<List<BlogPost>> newsPosts(Ref ref) async {
  final blogRepo = ref.watch(blogPostsRepositoryProvider);
  final parishIds = await UserParishPreferences.getPreferredParishIds();
  return blogRepo.listApproved(forParishIds: parishIds.isEmpty ? null : parishIds);
}

@riverpod
Future<List<Parish>> newsParishes(Ref ref) async {
  final parishRepo = ref.watch(parishRepositoryProvider);
  return parishRepo.listParishes();
}

@riverpod
Future<BlogPost?> newsPost(Ref ref, String postId) async {
  final blogRepo = ref.watch(blogPostsRepositoryProvider);
  final post = await blogRepo.getById(postId);
  if (post != null && (post.status == 'approved' || post.status == 'published')) {
    return post;
  }
  return null;
}

@riverpod
Future<List<BlogPost>> newsRecentPosts(Ref ref, {String? excludePostId}) async {
  final blogRepo = ref.watch(blogPostsRepositoryProvider);
  final parishIds = await UserParishPreferences.getPreferredParishIds();
  final posts = await blogRepo.listApproved(limit: 20, forParishIds: parishIds.isEmpty ? null : parishIds);
  
  var filtered = posts;
  if (excludePostId != null) {
    filtered = posts.where((p) => p.id != excludePostId).toList();
  }
  return filtered.take(4).toList();
}
