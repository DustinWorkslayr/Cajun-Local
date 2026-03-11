import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/messaging/data/models/conversation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversations_api.g.dart';

class ConversationsApi {
  ConversationsApi(this._client);
  final ApiClient _client;

  /// Fetch user conversations.
  Future<List<Conversation>> list({int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get('/conversations/', queryParameters: {'skip': skip, 'limit': limit});
      final data = response.data as List;
      return data.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list conversations');
    }
  }

  /// Get specific conversation by ID.
  Future<Conversation?> getById(String id) async {
    try {
      final response = await _client.dio.get('/conversations/$id');
      return Conversation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get conversation');
    }
  }

  /// Get conversations for a business.
  Future<List<Conversation>> listForBusiness(String businessId, {int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get(
        '/conversations/business/$businessId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list business conversations');
    }
  }

  /// Create a conversation.
  Future<Conversation> create(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/conversations/', data: data);
      return Conversation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create conversation');
    }
  }
}

@riverpod
ConversationsApi conversationsApi(ConversationsApiRef ref) {
  return ConversationsApi(ApiClient.instance);
}
