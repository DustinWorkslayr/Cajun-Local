import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/email_template.dart';
import 'package:my_app/core/data/repositories/email_templates_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: create a new email template. Uses homepage-style theme.
class AdminAddEmailTemplateScreen extends StatefulWidget {
  const AdminAddEmailTemplateScreen({super.key});

  @override
  State<AdminAddEmailTemplateScreen> createState() => _AdminAddEmailTemplateScreenState();
}

class _AdminAddEmailTemplateScreenState extends State<AdminAddEmailTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final t = EmailTemplate(
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      );
      await EmailTemplatesRepository().upsert(t);
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = 'Template created.';
        });
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _success = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Add email template',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. welcome_email',
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
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _success ? Colors.green : AppTheme.specRed,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppPrimaryButton(
                onPressed: _saving ? null : _submit,
                expanded: true,
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create template'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
