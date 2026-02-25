import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/contact_form_templates.dart';
import 'package:my_app/core/data/models/form_submission.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/conversations_repository.dart';
import 'package:my_app/core/data/repositories/form_submissions_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/messaging/presentation/screens/conversation_thread_screen.dart';

/// Inbox of contact form submissions for businesses the current user manages.
/// Shows which listing each submission is for when user has multiple businesses.
/// When [singleBusinessId] is set, only submissions for that business are shown (e.g. when embedded in a listing tab).
/// When [embeddedInTab] is true, only the body is built (no Scaffold/AppBar) for use inside ListingEditScreen.
class FormSubmissionsInboxScreen extends StatefulWidget {
  const FormSubmissionsInboxScreen({
    super.key,
    this.singleBusinessId,
    this.embeddedInTab = false,
  });

  final String? singleBusinessId;
  final bool embeddedInTab;

  @override
  State<FormSubmissionsInboxScreen> createState() => _FormSubmissionsInboxScreenState();
}

class _FormSubmissionsInboxScreenState extends State<FormSubmissionsInboxScreen> {
  List<FormSubmission> _submissions = [];
  Map<String, Profile?> _userProfiles = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _loading = false;
        _error = 'Not configured';
      });
      return;
    }
    final uid = AuthRepository().currentUserId;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final businessIds = widget.singleBusinessId != null
          ? [widget.singleBusinessId!]
          : await BusinessManagersRepository().listBusinessIdsForUser(uid);
      if (businessIds.isEmpty) {
        if (mounted) {
          setState(() {
            _submissions = [];
            _loading = false;
          });
        }
        return;
      }
      final namesById = <String, String>{};
      for (final id in businessIds) {
        final b = await BusinessRepository().getByIdForManager(id);
        if (b != null) namesById[id] = b.name;
      }
      final list = await FormSubmissionsRepository().listForBusinesses(
        businessIds,
        businessNamesById: namesById,
      );
      final userIds = list.map((s) => s.userId).toSet().toList();
      final profiles = <String, Profile?>{};
      for (final uid in userIds) {
        profiles[uid] = await AuthRepository().getProfileForAdmin(uid);
      }
      if (mounted) {
        setState(() {
          _submissions = list;
          _userProfiles = profiles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openConversation(BuildContext context, FormSubmission s) async {
    try {
      final conv = await ConversationsRepository().getOrCreate(
        businessId: s.businessId,
        userId: s.userId,
        subject: ContactFormTemplates.getByKey(s.template)?.name,
      );
      if (!context.mounted) return;
      final userDisplayName = await AuthRepository().getProfileForAdmin(s.userId)
          .then((p) => p?.displayName ?? p?.email);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationThreadScreen(
            conversationId: conv.id,
            conversation: conv,
            userDisplayName: userDisplayName,
            isBusinessManager: true,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: $e')),
        );
      }
    }
  }

  Future<void> _markReadAndExpand(FormSubmission s) async {
    if (!s.isRead) {
      await FormSubmissionsRepository().markRead(s.id);
      if (mounted) {
        setState(() {
          _submissions = _submissions
              .map((e) => e.id == s.id ? FormSubmission(
                    id: e.id,
                    businessId: e.businessId,
                    userId: e.userId,
                    template: e.template,
                    data: e.data,
                    isRead: true,
                    createdAt: e.createdAt,
                    businessName: e.businessName,
                    adminNote: e.adminNote,
                    repliedAt: e.repliedAt,
                    repliedBy: e.repliedBy,
                  ) : e)
              .toList();
        });
      }
    }
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              AppSecondaryButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.specNavy.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy),
            ),
            const SizedBox(height: 8),
            Text(
              widget.singleBusinessId != null
                  ? 'Messages for this listing will appear here.'
                  : 'Messages from your listing(s) will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _submissions.length,
        itemBuilder: (context, index) {
          final s = _submissions[index];
          final profile = _userProfiles[s.userId];
          final displayName = profile?.displayName?.trim().isNotEmpty == true
              ? profile!.displayName
              : profile?.email;
          return _SubmissionTile(
            submission: s,
            userDisplayName: displayName ?? 'Customer',
            userAvatarUrl: profile?.avatarUrl,
            onTap: () => _markReadAndExpand(s),
            onReply: () => _openConversation(context, s),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInTab) {
      return _buildBody(context);
    }
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: AppTheme.specNavy, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.specWhite,
        foregroundColor: AppTheme.specNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}

class _SubmissionTile extends StatefulWidget {
  const _SubmissionTile({
    required this.submission,
    required this.userDisplayName,
    this.userAvatarUrl,
    required this.onTap,
    required this.onReply,
  });

  final FormSubmission submission;
  final String userDisplayName;
  final String? userAvatarUrl;
  final VoidCallback onTap;
  final VoidCallback onReply;

  @override
  State<_SubmissionTile> createState() => _SubmissionTileState();
}

class _SubmissionTileState extends State<_SubmissionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.submission;
    final templateName = ContactFormTemplates.getByKey(s.template)?.name ?? s.template;
    final summary = _dataSummary(s.data);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          onTap: () {
            widget.onTap();
            setState(() => _expanded = !_expanded);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.specNavy.withValues(alpha: 0.08),
                      backgroundImage: widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty
                          ? NetworkImage(widget.userAvatarUrl!)
                          : null,
                      child: widget.userAvatarUrl == null || widget.userAvatarUrl!.isEmpty
                          ? Icon(Icons.person_rounded, color: AppTheme.specNavy.withValues(alpha: 0.5), size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userDisplayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.specNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            templateName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: s.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: AppTheme.specNavy.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (s.businessName != null)
                      Flexible(
                        child: Text(
                          s.businessName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(s.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.6),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppTheme.specNavy,
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.85),
                    ),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                ],
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppSecondaryButton(
                      onPressed: widget.onReply,
                      icon: const Icon(Icons.reply_rounded, size: 18),
                      label: const Text('Reply'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...s.data.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                _labelForKey(e.key),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value?.toString() ?? '—',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'Note',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.specGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        s.adminNote!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dataSummary(Map<String, dynamic> data) {
    final parts = <String>[];
    for (final k in ['name', 'email', 'message', 'description', 'notes', 'details']) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        parts.add(v.toString().trim());
      }
    }
    if (parts.isEmpty) {
      for (final v in data.values) {
        if (v != null && v.toString().trim().isNotEmpty) {
          parts.add(v.toString().trim());
          if (parts.length >= 2) break;
        }
      }
    }
    return parts.take(3).join(' · ');
  }

  String _labelForKey(String key) {
    for (final t in ContactFormTemplates.templates) {
      for (final f in t.fields) {
        if (f.key == key) return f.label;
      }
    }
    return key;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}/${d.day}/${d.year}';
  }
}

