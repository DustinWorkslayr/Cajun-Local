import 'package:my_app/core/data/models/message.dart';
import 'package:my_app/core/data/repositories/conversations_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Messages (messaging-faqs-cheatsheet §1.2). RLS: participants can SELECT/INSERT.
class MessagesRepository {
  MessagesRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// List messages in a conversation, oldest first.
  Future<List<Message>> listByConversation(String conversationId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (list as List)
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Send a message. Updates conversation last_message_at.
  Future<Message> insert({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final data = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body.trim(),
    };
    final list = await client.from('messages').insert(data).select();
    if (list.isEmpty) throw StateError('Message insert failed');
    await ConversationsRepository().touchLastMessageAt(conversationId);
    return Message.fromJson(Map<String, dynamic>.from(list.first));
  }
}
