import 'package:flutter/material.dart';
import 'package:my_app/core/data/repositories/notification_banners_repository.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Admin: create a notification banner. Uses homepage-style theme.
class AdminAddNotificationBannerScreen extends StatefulWidget {
  const AdminAddNotificationBannerScreen({super.key});

  @override
  State<AdminAddNotificationBannerScreen> createState() =>
      _AdminAddNotificationBannerScreenState();
}

class _AdminAddNotificationBannerScreenState
    extends State<AdminAddNotificationBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final id =
          'nb-${DateTime.now().millisecondsSinceEpoch}-${_titleController.text.hashCode.abs()}';
      await NotificationBannersRepository().insert({
        'id': id,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'is_active': _isActive,
      });
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = 'Banner created.';
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
          'Add notification banner',
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  'Active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.specNavy,
                  ),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppTheme.specGold,
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
                expanded: false,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create banner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
