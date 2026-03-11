import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/profile/data/models/profile.dart';
import 'package:cajun_local/features/notifications/data/repositories/notifications_repository.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/features/profile/data/repositories/profiles_repository.dart';

/// Admin: send a per-user notification. Select user, title, optional type.
class AdminSendNotificationScreen extends ConsumerStatefulWidget {
  const AdminSendNotificationScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<AdminSendNotificationScreen> createState() => _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState extends ConsumerState<AdminSendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _typeController = TextEditingController();
  final _actionUrlController = TextEditingController();
  List<Profile> _profiles = [];
  Profile? _selectedProfile;
  bool _loading = true;
  bool _sending = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final auth = ref.read(profilesRepositoryProvider);
    final list = await auth.listProfilesForAdmin();
    if (mounted) {
      setState(() {
        _profiles = list;
        _loading = false;
        if (list.isNotEmpty && _selectedProfile == null) _selectedProfile = list.first;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _typeController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfile == null) {
      setState(() {
        _message = 'Select a user.';
        _success = false;
      });
      return;
    }
    setState(() {
      _message = null;
      _sending = true;
    });
    try {
      await NotificationsRepository().insert(
        userId: _selectedProfile!.userId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
        type: _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
        actionUrl: _actionUrlController.text.trim().isEmpty ? null : _actionUrlController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sending = false;
          _success = true;
          _message =
              'Notification sent to ${_selectedProfile!.displayName ?? _selectedProfile!.email ?? _selectedProfile!.userId}.';
        });
        _titleController.clear();
        _bodyController.clear();
        _typeController.clear();
        _actionUrlController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _success = false;
          _message = e.toString();
        });
      }
    }
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Profile>(
              initialValue: _selectedProfile,
              decoration: const InputDecoration(
                labelText: 'Send to',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
              ),
              items: _profiles
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName ?? p.email ?? p.userId, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _selectedProfile = p),
              validator: (v) => v == null ? 'Select a user' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                hintText: 'Short headline',
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body (optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                hintText: 'Longer description for the notification',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type (optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                hintText: 'e.g. deal, reminder, listing, system',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actionUrlController,
              decoration: const InputDecoration(
                labelText: 'Action URL (optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.specWhite,
                hintText: 'https://... or app deep link',
              ),
              keyboardType: TextInputType.url,
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(color: _success ? Colors.green : AppTheme.specRed),
              ),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: _sending ? null : _submit,
              expanded: true,
              child: _sending
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send notification'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) return _buildBody(context);
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
          'Send notification',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
      ),
      body: _buildBody(context),
    );
  }
}
