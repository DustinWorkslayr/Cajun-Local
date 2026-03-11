import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blog_posts_api.g.dart';

class BlogPostsApi {
  BlogPostsApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listPosts({
    List<String>? statuses,
    List<String>? parishIds,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/blog-posts/',
        queryParameters: {
          if (statuses != null) 'statuses': statuses,
          if (parishIds != null) 'parish_ids': parishIds,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list blog posts');
    }
  }

  Future<Map<String, dynamic>> getPostById(String id) async {
    try {
      final response = await _client.dio.get('/blog-posts/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get blog post');
    }
  }

  Future<Map<String, dynamic>> getPostBySlug(String slug) async {
    try {
      final response = await _client.dio.get('/blog-posts/slug/$slug');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get blog post by slug');
    }
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/blog-posts/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create blog post');
    }
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/blog-posts/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to update blog post');
    }
  }
}

@riverpod
BlogPostsApi blogPostsApi(BlogPostsApiRef ref) {
  return BlogPostsApi(ApiClient.instance);
}
