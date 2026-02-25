import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/conversation.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/conversations_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/messaging/presentation/screens/conversation_thread_screen.dart';

/// List of conversations for the current user (as customer). Tapping opens the thread.
class MyConversationsScreen extends StatefulWidget {
  const MyConversationsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<MyConversationsScreen> createState() => _MyConversationsScreenState();
}

class _MyConversationsScreenState extends State<MyConversationsScreen> {
  List<Conversation> _conversations = [];
  Map<String, String> _businessNames = {};
  Map<String, String> _businessLogos = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ConversationsRepository().listForUser(widget.userId);
      final ids = list.map((c) => c.businessId).toSet().toList();
      final names = <String, String>{};
      final logos = <String, String>{};
      for (final id in ids) {
        final b = await BusinessRepository().getById(id);
        if (b != null) {
          names[id] = b.name;
          if (b.logoUrl != null && b.logoUrl!.isNotEmpty) logos[id] = b.logoUrl!;
        }
      }
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _businessNames = names;
        _businessLogos = logos;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year != now.year || dt.month != now.month || dt.day != now.day) {
      return '${dt.month}/${dt.day}/${dt.year}';
    }
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.specWhite,
        foregroundColor: AppTheme.specNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.specGold))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No conversations yet. Submit a contact form on a business to start one.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          AppLayout.horizontalPadding(context).left,
                          16,
                          AppLayout.horizontalPadding(context).right,
                          24,
                        ),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final c = _conversations[index];
                          final businessName =
                              _businessNames[c.businessId] ?? 'Business';
                          final logoUrl = _businessLogos[c.businessId];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppTheme.specWhite,
                              borderRadius: BorderRadius.circular(14),
                              elevation: 1,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ConversationThreadScreen(
                                        conversationId: c.id,
                                        conversation: c,
                                        businessName: businessName,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppTheme.specNavy.withValues(alpha: 0.08),
                                        backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                                            ? NetworkImage(logoUrl)
                                            : null,
                                        child: logoUrl == null || logoUrl.isEmpty
                                            ? Icon(Icons.store_rounded, color: AppTheme.specNavy.withValues(alpha: 0.5), size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              businessName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: AppTheme.specNavy,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (c.subject != null && c.subject!.trim().isNotEmpty)
                                                  c.subject!,
                                                _formatTime(c.lastMessageAt),
                                              ]
                                                  .where((e) => e.isNotEmpty)
                                                  .join(' · '),
                                              style: TextStyle(
                                                color: AppTheme.specNavy.withValues(alpha: 0.7),
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: AppTheme.specNavy.withValues(alpha: 0.6), size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
