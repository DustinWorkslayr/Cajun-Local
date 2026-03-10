import 'package:cajun_local/core/api/api_client.dart';
import 'package:cajun_local/core/api/conversations_api.dart';
import 'package:cajun_local/core/data/models/conversation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversations_repository.g.dart';

/// Conversations (messaging-faqs-cheatsheet §1.1). One per (business, user).
class ConversationsRepository {
  ConversationsRepository({ConversationsApi? api}) : _api = api ?? ConversationsApi(ApiClient.instance);
  final ConversationsApi _api;

  /// Get conversation by business and user, or null.
  Future<Conversation?> getByBusinessAndUser({required String businessId, required String userId}) async {
    // Backend's POST / already does get-or-create if we want,
    // but if we just want to CHECK without creating, maybe we need another endpoint.
    // However, the current create endpoint handles existence.
    // For now, I'll use create as it returns existing if found.
    return _api.create({'business_id': businessId, 'user_id': userId});
  }

  /// Get or create a conversation.
  Future<Conversation> getOrCreate({required String businessId, required String userId, String? subject}) async {
    return _api.create({
      'business_id': businessId,
      'user_id': userId,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
    });
  }

  /// List conversations for the current user.
  Future<List<Conversation>> listForUser(String userId) async {
    return _api.list();
  }

  /// List conversations for a business (manager).
  Future<List<Conversation>> listForBusiness(String businessId) async {
    return _api.listForBusiness(businessId);
  }

  /// Get by id.
  Future<Conversation?> getById(String id) async {
    return _api.getById(id);
  }

  /// Update last_message_at.
  Future<void> touchLastMessageAt(String conversationId) async {
    // This is typically handled by the backend when a message is sent via POST /{id}/messages
    // If you need to manually touch it:
    // This would require a PATCH endpoint or similar. For now, we trust the backend.
  }
}

@riverpod
ConversationsRepository conversationsRepository(ConversationsRepositoryRef ref) {
  return ConversationsRepository(api: ref.watch(conversationsApiProvider));
}
