import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/features/messaging/data/models/message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages_api.g.dart';

class MessagesApi {
  MessagesApi(this._client);
  final ApiClient _client;

  /// Fetch messages in a conversation.
  Future<List<Message>> listByConversation(String conversationId, {int skip = 0, int limit = 100}) async {
    try {
      final response = await _client.dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to list messages');
    }
  }

  /// Send a message.
  Future<Message> send(String conversationId, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/conversations/$conversationId/messages', data: data);
      return Message.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to send message');
    }
  }
}

@riverpod
MessagesApi messagesApi(MessagesApiRef ref) {
  return MessagesApi(ApiClient.instance);
}
