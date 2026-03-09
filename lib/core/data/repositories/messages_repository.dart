import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/messages_api.dart';
import 'package:my_app/core/data/models/message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages_repository.g.dart';

/// Messages (messaging-faqs-cheatsheet §1.2). RLS: participants can SELECT/INSERT.
class MessagesRepository {
  MessagesRepository({MessagesApi? api}) : _api = api ?? MessagesApi(ApiClient.instance);
  final MessagesApi _api;

  /// List messages in a conversation, oldest first.
  Future<List<Message>> listByConversation(String conversationId) async {
    return _api.listByConversation(conversationId);
  }

  /// Send a message. Updates conversation last_message_at.
  Future<Message> insert({required String conversationId, required String senderId, required String body}) async {
    return _api.send(conversationId, {'sender_id': senderId, 'body': body.trim()});
  }
}

@riverpod
MessagesRepository messagesRepository(MessagesRepositoryRef ref) {
  return MessagesRepository(api: ref.watch(messagesApiProvider));
}
