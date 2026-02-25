import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/conversation.dart';
import 'package:my_app/core/data/models/message.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/conversations_repository.dart';
import 'package:my_app/core/data/repositories/messages_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Two-way conversation thread. User messages on right, business on left.
/// User can only send when the last message is from the business.
class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({
    super.key,
    required this.conversationId,
    this.conversation,
    this.businessName,
    this.userDisplayName,
    this.isBusinessManager = false,
  });

  final String conversationId;
  final Conversation? conversation;
  final String? businessName;
  final String? userDisplayName;
  /// When true, current user is replying as business (can always send).
  final bool isBusinessManager;

  @override
  State<ConversationThreadScreen> createState() => _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  Conversation? _conversation;
  List<Message> _messages = [];
  bool _loading = true;
  String? _error;
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _otherPartyName;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _otherPartyName = widget.businessName ?? widget.userDisplayName;
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final convRepo = ConversationsRepository();
    final msgRepo = MessagesRepository();
    final conv = _conversation ?? await convRepo.getById(widget.conversationId);
    if (conv == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Conversation not found';
        });
      }
      return;
    }
    final messages = await msgRepo.listByConversation(conv.id);
    String? otherName = widget.businessName ?? widget.userDisplayName;
    if (widget.isBusinessManager) {
      otherName ??= await _getUserDisplayName(conv.userId);
    } else {
      otherName ??= await BusinessRepository().getById(conv.businessId).then((b) => b?.name);
    }
    if (!mounted) return;
    setState(() {
      _conversation = conv;
      _messages = messages;
      _loading = false;
      _otherPartyName = otherName ?? (widget.isBusinessManager ? 'Customer' : 'Business');
    });
  }

  Future<String?> _getUserDisplayName(String userId) async {
    final p = await AuthRepository().getProfileForAdmin(userId);
    return p?.displayName?.trim().isNotEmpty == true ? p!.displayName : p?.email;
  }

  /// User (customer) can send only when last message is from business (sender_id != conversation.user_id).
  bool get _userCanSend {
    if (_conversation == null) return false;
    if (widget.isBusinessManager) return true;
    if (_messages.isEmpty) return false;
    final last = _messages.last;
    return last.senderId != _conversation!.userId;
  }

  String _formatTime(DateTime? d) {
    if (d == null) return '';
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _conversation == null) return;
    if (!widget.isBusinessManager && !_userCanSend) return;
    final uid = AuthRepository().currentUserId;
    if (uid == null) return;
    setState(() => _sending = true);
    try {
      final msg = await MessagesRepository().insert(
        conversationId: _conversation!.id,
        senderId: uid,
        body: body,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = [..._messages, msg];
        _sending = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final isUser = !widget.isBusinessManager;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          title: Text(_otherPartyName ?? 'Conversation', style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.specWhite,
          foregroundColor: AppTheme.specNavy,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          title: const Text('Conversation', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.specWhite,
          foregroundColor: AppTheme.specNavy,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 16),
                AppSecondaryButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(_otherPartyName ?? 'Conversation', style: const TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.specWhite,
        foregroundColor: AppTheme.specNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 12),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final fromUser = msg.senderId == _conversation!.userId;
                final alignRight = isUser && fromUser;
                final senderLabel = fromUser
                    ? (isUser ? 'You' : (_otherPartyName ?? 'Customer'))
                    : (_otherPartyName ?? 'Business');
                return _MessageBubble(
                  body: msg.body,
                  senderLabel: senderLabel,
                  time: _formatTime(msg.createdAt),
                  isFromMe: isUser && fromUser,
                  alignRight: alignRight,
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 8 + MediaQuery.paddingOf(context).bottom),
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _userCanSend || widget.isBusinessManager
                            ? 'Type a message…'
                            : 'Wait for the business to reply',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      enabled: _userCanSend || widget.isBusinessManager,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (_userCanSend || widget.isBusinessManager) && !_sending
                        ? _send
                        : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.specNavy,
                      foregroundColor: AppTheme.specWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.body,
    required this.senderLabel,
    required this.time,
    required this.isFromMe,
    required this.alignRight,
  });

  final String body;
  final String senderLabel;
  final String time;
  final bool isFromMe;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: Column(
            crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                senderLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFromMe
                      ? AppTheme.specNavy
                      : AppTheme.specGold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(alignRight ? 16 : 4),
                    bottomRight: Radius.circular(alignRight ? 4 : 16),
                  ),
                ),
                child: Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isFromMe ? AppTheme.specWhite : AppTheme.specNavy,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
