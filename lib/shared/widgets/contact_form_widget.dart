import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/contact_form_templates.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/conversations_repository.dart';
import 'package:my_app/core/data/repositories/form_submissions_repository.dart';
import 'package:my_app/core/data/repositories/messages_repository.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/theme.dart';

/// Renders the business's contact form (template-based). Shown on listing detail.
/// When Supabase is off or business has no contact_form_template, shows nothing.
class ContactFormWidget extends StatefulWidget {
  const ContactFormWidget({
    super.key,
    required this.businessId,
    this.businessName,
    this.isSignedIn = false,
    this.onConversationStarted,
  });

  final String businessId;
  final String? businessName;
  final bool isSignedIn;
  /// Called after successful submit with conversationId so caller can open the thread.
  final void Function(String conversationId)? onConversationStarted;

  @override
  State<ContactFormWidget> createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends State<ContactFormWidget> {
  Business? _business;
  bool _loading = true;
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final b = await BusinessRepository().getById(widget.businessId);
    if (!mounted) return;
    if (b != null &&
        b.contactFormTemplate != null &&
        ContactFormTemplates.getByKey(b.contactFormTemplate!) != null) {
      final def = ContactFormTemplates.getByKey(b.contactFormTemplate!);
      for (final f in def!.fields) {
        _controllers[f.key] = TextEditingController();
      }
    }
    setState(() {
      _business = b;
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(ContactFormFieldDef field, String value) {
    if (field.required && (value.trim().isEmpty)) return 'Required';
    if (field.type == ContactFormFieldType.email &&
        value.trim().isNotEmpty &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _submit() async {
    final templateKey = _business!.contactFormTemplate!;
    final def = ContactFormTemplates.getByKey(templateKey);
    if (def == null) return;
    final uid = AuthRepository().currentUserId;
    if (uid == null) {
      setState(() => _error = 'You must be signed in to submit.');
      return;
    }
    final data = <String, String>{};
    for (final f in def.fields) {
      final c = _controllers[f.key];
      final v = c?.text.trim() ?? '';
      final err = _validate(f, v);
      if (err != null) {
        setState(() => _error = '${f.label}: $err');
        return;
      }
      data[f.key] = v;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await FormSubmissionsRepository().insert(
        businessId: widget.businessId,
        userId: uid,
        template: templateKey,
        data: data,
      );
      final templateName = def.name;
      final convRepo = ConversationsRepository();
      final msgRepo = MessagesRepository();
      final conv = await convRepo.getOrCreate(
        businessId: widget.businessId,
        userId: uid,
        subject: templateName,
      );
      // Build first message with all form data so the business owner sees the full submission.
      final lines = <String>['Contact form: $templateName', ''];
      for (final f in def.fields) {
        final v = data[f.key]?.toString().trim();
        if (v != null && v.isNotEmpty) {
          lines.add('${f.label}: $v');
        }
      }
      final firstBody = lines.join('\n');
      await msgRepo.insert(
        conversationId: conv.id,
        senderId: uid,
        body: firstBody.length > 2000 ? '${firstBody.substring(0, 2000)}…' : firstBody,
      );
      if (!mounted) return;
      for (final c in _controllers.values) {
        c.clear();
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent. The business will get back to you.'),
          backgroundColor: AppTheme.specNavy,
        ),
      );
      widget.onConversationStarted?.call(conv.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (_business == null ||
        _business!.contactFormTemplate == null ||
        _business!.contactFormTemplate!.trim().isEmpty) {
      return Text(
        'This business hasn\'t set up a contact form.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final def = ContactFormTemplates.getByKey(_business!.contactFormTemplate!);
    if (def == null) {
      return Text(
        'Contact form is not available.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contact ${widget.businessName ?? 'this business'}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          def.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!widget.isSignedIn) ...[
          const SizedBox(height: 12),
          Text(
            'Sign in to send a message.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          ...def.fields.map((f) {
            final c = _controllers[f.key];
            if (c == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: c,
                decoration: InputDecoration(
                  labelText: f.label,
                  hintText: f.hint,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                keyboardType: f.type == ContactFormFieldType.email
                    ? TextInputType.emailAddress
                    : f.type == ContactFormFieldType.phone
                        ? TextInputType.phone
                        : f.type == ContactFormFieldType.textarea
                            ? TextInputType.multiline
                            : TextInputType.text,
                maxLines: f.type == ContactFormFieldType.textarea ? 4 : 1,
                textInputAction: f.type == ContactFormFieldType.textarea
                    ? TextInputAction.newline
                    : TextInputAction.next,
                inputFormatters: f.type == ContactFormFieldType.phone
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-+()]'))]
                    : null,
              ),
            );
          }),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          AppSecondaryButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send message'),
          ),
        ],
      ],
    );
  }
}
