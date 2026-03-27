import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/services/app_storage_service.dart';
import 'package:cajun_local/core/data/services/storage_upload_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

class ProfileHeaderWidget extends ConsumerStatefulWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.onRefresh,
  });

  final MockUser user;
  final VoidCallback onRefresh;

  @override
  ConsumerState<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends ConsumerState<ProfileHeaderWidget> {
  bool _uploadingAvatar = false;
  bool _profileEditing = false;
  late String _displayName;
  late String? _email;
  TextEditingController? _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayName = widget.user.displayName;
    _email = widget.user.email;
  }

  @override
  void didUpdateWidget(covariant ProfileHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.displayName != widget.user.displayName) _displayName = widget.user.displayName;
    if (oldWidget.user.email != widget.user.email) _email = widget.user.email;
  }

  @override
  void dispose() {
    _displayNameController?.dispose();
    super.dispose();
  }

  Future<void> _pickAndSetProfilePhoto() async {
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to add a profile picture')));
      return;
    }
    if (_uploadingAvatar) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final url = await AppStorageService().uploadAvatar(userId: uid, bytes: bytes, extension: ext);
      await ref.read(authControllerProvider.notifier).updateProfile(avatarUrl: url);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.specRed));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _startEdit() {
    _displayNameController = TextEditingController(text: _displayName);
    setState(() => _profileEditing = true);
  }

  Future<void> _saveProfile() async {
    final newName = _displayNameController?.text.trim() ?? _displayName;
    final displayName = newName.isEmpty ? widget.user.displayName : newName;

    setState(() {
      _profileEditing = false;
      _displayName = displayName;
    });

    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid != null && displayName.isNotEmpty && displayName != widget.user.displayName) {
      try {
        await ref.read(authControllerProvider.notifier).updateProfile(displayName: displayName);
        if (mounted) widget.onRefresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: $e'), backgroundColor: AppTheme.specRed));
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _profileEditing = false;
      _displayName = widget.user.displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAndSetProfilePhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.specNavy.withValues(alpha: 0.05),
                    backgroundImage: (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(widget.user.avatarUrl!)
                        : null,
                    child: _uploadingAvatar
                        ? const CircularProgressIndicator(color: AppTheme.specNavy, strokeWidth: 2)
                        : (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
                            ? Text(
                                _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.specNavy,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                  ),
                ),
                if (!_uploadingAvatar)
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.specNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.specWhite, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.specWhite),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_profileEditing) ...[
            TextField(
              controller: _displayNameController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
              decoration: InputDecoration(
                hintText: 'Your name',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.specGold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _cancelEdit,
                  child: Text('Cancel', style: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.6))),
                ),
                const SizedBox(width: 8),
                AppPrimaryButton(
                  expanded: false,
                  onPressed: _saveProfile,
                  label: const Text('Save Name'),
                ),
              ],
            ),
          ] else ...[
            Text(
              _displayName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.specNavy, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            if (_email != null && _email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _email!,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _startEdit,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.specNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: AppTheme.specNavy.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Edit Name',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
