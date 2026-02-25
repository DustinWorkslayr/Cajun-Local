import 'package:my_app/core/data/models/conversation.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conversations (messaging-faqs-cheatsheet §1.1). One per (business, user).
class ConversationsRepository {
  ConversationsRepository();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Get conversation by business and user, or null.
  Future<Conversation?> getByBusinessAndUser({
    required String businessId,
    required String userId,
  }) async {
    final client = _client;
    if (client == null) return null;
    final res = await client
        .from('conversations')
        .select()
        .eq('business_id', businessId)
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return Conversation.fromJson(Map<String, dynamic>.from(res));
  }

  /// Get or create a conversation. Creates with subject if provided. RLS: user can INSERT (user_id = auth.uid()).
  Future<Conversation> getOrCreate({
    required String businessId,
    required String userId,
    String? subject,
  }) async {
    final existing = await getByBusinessAndUser(
      businessId: businessId,
      userId: userId,
    );
    if (existing != null) return existing;
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final data = <String, dynamic>{
      'business_id': businessId,
      'user_id': userId,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
    };
    final list = await client.from('conversations').insert(data).select();
    if (list.isEmpty) throw StateError('Conversation insert failed');
    return Conversation.fromJson(Map<String, dynamic>.from(list.first));
  }

  /// List conversations for the current user (as customer). Newest last_message_at first.
  Future<List<Conversation>> listForUser(String userId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('last_message_at', ascending: false);
    return (list as List)
        .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// List conversations for a business (manager). All conversations with this business_id.
  Future<List<Conversation>> listForBusiness(String businessId) async {
    final client = _client;
    if (client == null) return [];
    final list = await client
        .from('conversations')
        .select()
        .eq('business_id', businessId)
        .order('last_message_at', ascending: false);
    return (list as List)
        .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get by id.
  Future<Conversation?> getById(String id) async {
    final client = _client;
    if (client == null) return null;
    final res = await client.from('conversations').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Conversation.fromJson(Map<String, dynamic>.from(res));
  }

  /// Update last_message_at (called when a new message is inserted).
  Future<void> touchLastMessageAt(String conversationId) async {
    final client = _client;
    if (client == null) return;
    await client.from('conversations').update({
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);
  }
}
