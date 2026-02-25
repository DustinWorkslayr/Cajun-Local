import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/email_template.dart';
import 'package:my_app/core/data/repositories/email_templates_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEmailTemplatesScreen extends StatefulWidget {
  const AdminEmailTemplatesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminEmailTemplatesScreen> createState() => _AdminEmailTemplatesScreenState();
}

class _AdminEmailTemplatesScreenState extends State<AdminEmailTemplatesScreen> {
  late Future<List<EmailTemplate>> _listFuture;

  @override
  void initState() {
    super.initState();
    _listFuture = EmailTemplatesRepository().list();
  }

  void _refresh() {
    setState(() {
      _listFuture = EmailTemplatesRepository().list();
    });
  }

  void _openSlideOut(BuildContext context, {EmailTemplate? template}) {
    EmailTemplateSlideOut.show(
      context,
      initialTemplate: template,
      onClose: () => Navigator.of(context).pop(),
      onSaved: _refresh,
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<EmailTemplate>>(
        future: _listFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No email templates.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final t = list[index];
              final bodyPreview = t.body.isNotEmpty
                  ? (t.body.length > 80 ? '${t.body.substring(0, 80)}…' : t.body)
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminListCard(
                  title: t.name,
                  subtitle: bodyPreview != null ? '${t.subject} · $bodyPreview' : t.subject,
                  badges: const [AdminBadgeData('Template')],
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.specGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.email_rounded, color: AppTheme.specNavy, size: 26),
                  ),
                  onTap: () => _openSlideOut(context, template: t),
                ),
              );
            },
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) {
      return Stack(
        children: [
          _buildBody(context),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _openSlideOut(context),
              tooltip: 'Add email template',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add email template',
            onPressed: () => _openSlideOut(context),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}

/// Slide-out panel: view (read-only) or edit template, with CRUD and "Send test email".
class EmailTemplateSlideOut extends StatefulWidget {
  const EmailTemplateSlideOut({
    super.key,
    required this.initialTemplate,
    required this.onClose,
    required this.onSaved,
  });

  final EmailTemplate? initialTemplate;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  static void show(
    BuildContext context, {
    EmailTemplate? initialTemplate,
    required VoidCallback onClose,
    required VoidCallback onSaved,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) => Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppTheme.specOffWhite,
            elevation: 24,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(ctx).width * 0.92).clamp(0.0, 420.0),
              ),
              child: SizedBox(
                width: double.infinity,
                child: EmailTemplateSlideOut(
                initialTemplate: initialTemplate,
                onClose: onClose,
                onSaved: onSaved,
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  @override
  State<EmailTemplateSlideOut> createState() => _EmailTemplateSlideOutState();
}

class _EmailTemplateSlideOutState extends State<EmailTemplateSlideOut> {
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _sendingTest = false;
  String? _message;
  bool _messageSuccess = false;
  /// When true and we have an existing template, show read-only view. Tapping Edit switches to form.
  bool _isViewMode = true;
  /// After save, we show this in view mode so view reflects latest data.
  EmailTemplate? _currentTemplate;
  bool get _isCreate => widget.initialTemplate == null;
  EmailTemplate get _templateForView => _currentTemplate ?? widget.initialTemplate!;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTemplate;
    _nameController = TextEditingController(text: t?.name ?? '');
    _subjectController = TextEditingController(text: t?.subject ?? '');
    _bodyController = TextEditingController(text: t?.body ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final template = EmailTemplate(
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      );
      await EmailTemplatesRepository().upsert(template);
      if (mounted) {
        final saved = EmailTemplate(
          name: _nameController.text.trim(),
          subject: _subjectController.text.trim(),
          body: _bodyController.text.trim(),
          updatedAt: DateTime.now(),
        );
        setState(() {
          _saving = false;
          _currentTemplate = saved;
          _message = _isCreate ? 'Template created.' : 'Template saved.';
          _messageSuccess = true;
          if (!_isCreate) _isViewMode = true;
        });
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = e.toString();
          _messageSuccess = false;
        });
      }
    }
  }

  Future<void> _deleteTemplate() async {
    if (widget.initialTemplate == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template'),
        content: Text(
          'Permanently delete the template "${widget.initialTemplate!.name}"? This cannot be undone.',
        ),
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
    if (confirmed != true || !mounted) return;
    setState(() { _saving = true; });
    try {
      await EmailTemplatesRepository().delete(widget.initialTemplate!.name);
      if (mounted) {
        widget.onSaved();
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = e.toString();
          _messageSuccess = false;
        });
      }
    }
  }

  Future<void> _sendTestEmail() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _message = 'Save the template first (name required) to send a test.';
        _messageSuccess = false;
      });
      return;
    }
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in with an email to send a test.')),
        );
      }
      return;
    }
    setState(() {
      _message = null;
      _sendingTest = true;
    });
    try {
      await SendEmailService().send(
        to: email,
        template: name,
        variables: {},
      );
      if (mounted) {
        setState(() {
          _sendingTest = false;
          _message = 'Test email sent to $email';
          _messageSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingTest = false;
          _message = 'Failed to send test: $e';
          _messageSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final showView = !_isCreate && _isViewMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isCreate
                      ? 'New email template'
                      : showView
                          ? 'Template'
                          : 'Edit template',
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
          child: showView ? _buildViewContent(theme, nav) : _buildFormContent(theme, nav),
        ),
      ],
    );
  }

  Widget _buildViewContent(ThemeData theme, Color nav) {
    final t = _templateForView;
    final updatedStr = t.updatedAt != null
        ? 'Updated ${t.updatedAt!.month}/${t.updatedAt!.day}/${t.updatedAt!.year}'
        : null;
    final sub = nav.withValues(alpha: 0.75);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: nav.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAME',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sub,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                if (updatedStr != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    updatedStr,
                    style: theme.textTheme.bodySmall?.copyWith(color: sub),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'SUBJECT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sub,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.subject.isEmpty ? '(empty)' : t.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BODY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sub,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.specOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nav.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    t.body.isEmpty ? '(No body)' : t.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: nav.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  onPressed: _sendingTest ? null : _sendTestEmail,
                  expanded: true,
                  icon: _sendingTest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: const Text('Send test'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  onPressed: () => setState(() => _isViewMode = false),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving ? null : _deleteTemplate,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Delete template'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.specRed),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _messageSuccess ? Colors.green : AppTheme.specRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme, Color nav) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isCreate) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() => _isViewMode = true),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to view'),
                ),
              ),
            ],
            TextFormField(
              controller: _nameController,
              readOnly: !_isCreate,
              decoration: InputDecoration(
                labelText: 'Template name',
                hintText: 'e.g. welcome_email',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                helperText: _isCreate ? null : 'Name cannot be changed when editing.',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              'Preview',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: nav,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nav.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject: ${_subjectController.text.isEmpty ? "(empty)" : _subjectController.text}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: nav,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bodyController.text.isEmpty ? '(No body)' : _bodyController.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: nav.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _messageSuccess ? Colors.green : AppTheme.specRed,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    onPressed: _sendingTest ? null : _sendTestEmail,
                    expanded: true,
                    icon: _sendingTest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Send test email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: _saving ? null : _save,
                    expanded: true,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                          )
                        : Text(_isCreate ? 'Create template' : 'Save'),
                  ),
                ),
              ],
            ),
            if (!_isCreate) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _deleteTemplate,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Delete template'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.specRed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
