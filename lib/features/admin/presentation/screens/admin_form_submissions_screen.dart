import 'package:flutter/material.dart';
import 'package:my_app/core/data/contact_form_templates.dart';
import 'package:my_app/core/data/models/form_submission.dart';
import 'package:my_app/core/data/repositories/form_submissions_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: list all form submissions, optional filter by business. Tap to open detail with note and delete.
class AdminFormSubmissionsScreen extends StatefulWidget {
  const AdminFormSubmissionsScreen({
    super.key,
    this.embeddedInShell = false,
    this.businessId,
  });

  final bool embeddedInShell;
  final String? businessId;

  @override
  State<AdminFormSubmissionsScreen> createState() =>
      _AdminFormSubmissionsScreenState();
}

class _AdminFormSubmissionsScreenState extends State<AdminFormSubmissionsScreen> {
  String? _businessIdFilter;

  @override
  void initState() {
    super.initState();
    _businessIdFilter = widget.businessId;
  }

  void _refresh() => setState(() {});

  void _openDetail(BuildContext context, FormSubmission submission) {
    AdminFormSubmissionDetailSlideOut.show(
      context,
      submission: submission,
      onClose: () => Navigator.of(context).pop(),
      onUpdated: _refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = FormSubmissionsRepository();

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Form submissions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.specNavy),
      ),
      body: FutureBuilder<List<FormSubmission>>(
        future: repo.listForAdmin(
          businessId: _businessIdFilter,
          limit: 100,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                _businessIdFilter != null
                    ? 'No submissions for this business.'
                    : 'No form submissions.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final s = list[index];
              final templateName =
                  ContactFormTemplates.getByKey(s.template)?.name ?? s.template;
              final dateStr = s.createdAt != null
                  ? '${s.createdAt!.month}/${s.createdAt!.day}/${s.createdAt!.year}'
                  : '—';
              final subtitle = '${s.businessName ?? s.businessId} · $templateName · $dateStr'
                  '${s.isRead ? '' : ' · Unread'}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminListCard(
                  title: s.adminNote?.isNotEmpty == true
                      ? s.adminNote!.length > 40
                          ? '${s.adminNote!.substring(0, 40)}…'
                          : s.adminNote!
                      : (s.data.isNotEmpty
                          ? (s.data.values.first?.toString().length ?? 0) > 30
                              ? '${s.data.values.first.toString().substring(0, 30)}…'
                              : s.data.values.first?.toString() ?? 'Submission'
                          : 'Submission'),
                  subtitle: subtitle,
                  badges: [
                    if (!s.isRead) AdminBadgeData('Unread', color: AppTheme.specRed),
                  ],
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.specGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      color: AppTheme.specNavy,
                      size: 26,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.specNavy,
                    size: 24,
                  ),
                  onTap: () => _openDetail(context, s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Slide-out: full submission data, admin note field, mark read, save note, delete.
class AdminFormSubmissionDetailSlideOut extends StatefulWidget {
  const AdminFormSubmissionDetailSlideOut({
    super.key,
    required this.submission,
    required this.onClose,
    required this.onUpdated,
  });

  final FormSubmission submission;
  final VoidCallback onClose;
  final VoidCallback onUpdated;

  static void show(
    BuildContext context, {
    required FormSubmission submission,
    required VoidCallback onClose,
    required VoidCallback onUpdated,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        final panelWidth =
            (MediaQuery.sizeOf(ctx).width * 0.92).clamp(0.0, 420.0);
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppTheme.specOffWhite,
              elevation: 24,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: panelWidth,
                  maxWidth: panelWidth,
                  minHeight: 0,
                  maxHeight: double.infinity,
                ),
                child: AdminFormSubmissionDetailSlideOut(
                  submission: submission,
                  onClose: onClose,
                  onUpdated: onUpdated,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdminFormSubmissionDetailSlideOut> createState() =>
      _AdminFormSubmissionDetailSlideOutState();
}

class _AdminFormSubmissionDetailSlideOutState
    extends State<AdminFormSubmissionDetailSlideOut> {
  late FormSubmission _submission;
  late TextEditingController _noteController;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _submission = widget.submission;
    _noteController =
        TextEditingController(text: widget.submission.adminNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final uid = AppDataScope.of(context).authRepository.currentUserId;
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      await FormSubmissionsRepository().update(
        _submission.id,
        adminNote: note,
        repliedBy: uid,
      );
      if (mounted) {
        setState(() {
          _submission = FormSubmission(
            id: _submission.id,
            businessId: _submission.businessId,
            userId: _submission.userId,
            template: _submission.template,
            data: _submission.data,
            isRead: _submission.isRead,
            createdAt: _submission.createdAt,
            businessName: _submission.businessName,
            adminNote: note,
            repliedAt: DateTime.now().toUtc(),
            repliedBy: uid,
          );
          _saving = false;
          _message = 'Note saved.';
        });
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Error: $e';
        });
      }
    }
  }

  Future<void> _markRead() async {
    setState(() => _saving = true);
    try {
      await FormSubmissionsRepository().update(_submission.id, isRead: true);
      if (mounted) {
        setState(() {
          _submission = FormSubmission(
            id: _submission.id,
            businessId: _submission.businessId,
            userId: _submission.userId,
            template: _submission.template,
            data: _submission.data,
            isRead: true,
            createdAt: _submission.createdAt,
            businessName: _submission.businessName,
            adminNote: _submission.adminNote,
            repliedAt: _submission.repliedAt,
            repliedBy: _submission.repliedBy,
          );
          _saving = false;
        });
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete submission?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await FormSubmissionsRepository().deleteForAdmin(_submission.id);
      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final templateName =
        ContactFormTemplates.getByKey(_submission.template)?.name ??
            _submission.template;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Submission',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
                color: nav,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Business',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _submission.businessName ?? _submission.businessId,
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 12),
                Text(
                  'Template',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  templateName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 12),
                Text(
                  'Submitted data',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.specWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nav.withValues(alpha: 0.15)),
                  ),
                  child: _submission.data.isEmpty
                      ? Text(
                          'No data',
                          style: theme.textTheme.bodySmall?.copyWith(color: sub),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _submission.data.entries
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${e.key}: ${e.value}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: nav),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Admin note',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Internal note or reply (visible to manager)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _message!.startsWith('Error')
                          ? AppTheme.specRed
                          : Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppSecondaryButton(
                      onPressed: _saving ? null : _saveNote,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save note'),
                    ),
                    if (!_submission.isRead)
                      AppOutlinedButton(
                        onPressed: _saving ? null : _markRead,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Mark read'),
                      ),
                    AppDangerOutlinedButton(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
