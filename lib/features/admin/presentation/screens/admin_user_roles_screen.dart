import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/data/models/user_role.dart';
import 'package:my_app/core/data/models/user_subscription.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/data/repositories/user_roles_repository.dart';
import 'package:my_app/core/data/repositories/user_subscriptions_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';

class AdminUserRolesScreen extends StatefulWidget {
  const AdminUserRolesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminUserRolesScreen> createState() => _AdminUserRolesScreenState();
}

class _AdminUserRolesScreenState extends State<AdminUserRolesScreen> {
  int _refreshKey = 0;

  static String _displayLabel(
    UserRole ur,
    Map<String, Profile> profileByUserId,
  ) {
    final p = profileByUserId[ur.userId];
    if (p != null && (p.displayName != null && p.displayName!.isNotEmpty)) {
      return p.displayName!;
    }
    if (p != null && (p.email != null && p.email!.isNotEmpty)) return p.email!;
    return 'User';
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authRepo = AuthRepository();
    final rolesRepo = UserRolesRepository();
    return FutureBuilder<List<UserRole>>(
      key: ValueKey(_refreshKey),
      future: rolesRepo.listForAdmin(),
      builder: (context, rolesSnapshot) {
        if (rolesSnapshot.connectionState == ConnectionState.waiting &&
            !rolesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final roles = rolesSnapshot.data ?? [];
        if (roles.isEmpty) {
          return Center(
            child: Text(
              'No users.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return FutureBuilder<List<Profile>>(
          future: authRepo.listProfilesForAdmin(),
          builder: (context, profilesSnapshot) {
            if (profilesSnapshot.connectionState == ConnectionState.waiting &&
                !profilesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final profiles = profilesSnapshot.data ?? [];
            final profileByUserId = {for (var p in profiles) p.userId: p};
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final ur = roles[index];
                final profile = profileByUserId[ur.userId];
                final label = _displayLabel(ur, profileByUserId);
                final avatarUrl = profile?.avatarUrl;
                final email = profile?.email ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminListCard(
                    title: label,
                    subtitle: email.isNotEmpty
                        ? email
                        : 'User ID: ${ur.userId}',
                    badges: [AdminBadgeData(ur.role)],
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.specGold.withValues(alpha: 0.2),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              color: AppTheme.specNavy,
                              size: 26,
                            )
                          : null,
                    ),
                    onTap: () => _showUserSheet(
                      context,
                      userId: ur.userId,
                      initialName: profile?.displayName ?? '',
                      initialEmail: profile?.email ?? '',
                      initialRole: ur.role,
                      initialAvatarUrl: profile?.avatarUrl,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showUserSheet(
    BuildContext context, {
    required String userId,
    required String initialName,
    required String initialEmail,
    required String initialRole,
    String? initialAvatarUrl,
  }) {
    AdminDetailPanel.show<void>(
      context: context,
      title: 'Edit user',
      child: _UserEditPanelContent(
        userId: userId,
        initialName: initialName,
        initialEmail: initialEmail,
        initialRole: initialRole,
        initialAvatarUrl: initialAvatarUrl,
        onSaved: () {
          setState(() => _refreshKey++);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) return _buildBody(context);
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
      ),
      body: _buildBody(context),
    );
  }
}

class _UserEditPanelContent extends StatefulWidget {
  const _UserEditPanelContent({
    required this.userId,
    required this.initialName,
    required this.initialEmail,
    required this.initialRole,
    required this.onSaved,
    this.initialAvatarUrl,
  });

  final String userId;
  final String initialName;
  final String initialEmail;
  final String initialRole;
  final VoidCallback onSaved;
  final String? initialAvatarUrl;

  @override
  State<_UserEditPanelContent> createState() => _UserEditPanelContentState();
}

class _UserEditPanelContentState extends State<_UserEditPanelContent> {
  late TextEditingController _nameController;
  late String _role;
  List<String> _managedBusinessIds = [];
  List<Business> _allBusinesses = [];
  List<UserPlan> _userPlans = [];
  UserSubscription? _subscription;
  String? _avatarUrl;
  bool _loading = true;
  bool _uploadingAvatar = false;
  String? _savingError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _role = widget.initialRole;
    _avatarUrl = widget.initialAvatarUrl;
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final managersRepo = BusinessManagersRepository();
    final businessRepo = BusinessRepository();
    final plansRepo = UserPlansRepository();
    final subsRepo = UserSubscriptionsRepository();
    final ids = await managersRepo.listBusinessIdsForUser(widget.userId);
    final businesses = await businessRepo.listForAdmin();
    final plans = await plansRepo.list();
    final sub = await subsRepo.getByUserId(widget.userId);
    if (!mounted) return;
    setState(() {
      _managedBusinessIds = ids;
      _allBusinesses = businesses;
      _userPlans = plans.where((p) => p.isActive).toList();
      _subscription = sub;
      _loading = false;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
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
      final url = await AppStorageService().uploadAvatar(
        userId: widget.userId,
        bytes: bytes,
        extension: ext,
      );
      await AuthRepository().updateProfileForAdmin(
        widget.userId,
        avatarUrl: url,
      );
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _uploadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _assignPlan(String? planId) async {
    final repo = UserSubscriptionsRepository();
    try {
      if (planId == null || planId.isEmpty) {
        await repo.deleteByUserId(widget.userId);
        if (mounted) {
          setState(() => _subscription = null);
        }
      } else {
        await repo.setPlanForUser(widget.userId, planId);
        if (mounted) {
          setState(
            () => _subscription = UserSubscription(
              id: '',
              userId: widget.userId,
              planId: planId,
            ),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _downgradeUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Downgrade user'),
        content: const Text(
          'Set role to User and remove subscription. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await UserRolesRepository().setRole(widget.userId, 'user');
      await UserSubscriptionsRepository().deleteByUserId(widget.userId);
      if (mounted) {
        setState(() {
          _role = 'user';
          _subscription = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User downgraded')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user'),
        content: const Text(
          'Remove this user from the app (profile, role, subscription). '
          'For full account deletion use Supabase Dashboard > Authentication > Users. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          AppDangerButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AuthRepository().removeUserFromApp(widget.userId);
      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User removed. Use Dashboard for full auth deletion.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _saveNameAndRole() async {
    setState(() => _savingError = null);
    if (!UserRolesRepository.isValidUserId(widget.userId)) {
      if (mounted) {
        setState(() {
          _savingError =
              'This user\'s ID is not a valid UUID. user_roles expects Supabase auth user IDs. '
              'Fix or remove this row in Supabase Dashboard (Table Editor > user_roles).';
        });
      }
      return;
    }
    final authRepo = AuthRepository();
    final rolesRepo = UserRolesRepository();
    try {
      final name = _nameController.text.trim();
      await authRepo.updateProfileForAdmin(
        widget.userId,
        displayName: name.isEmpty ? null : name,
      );
      await rolesRepo.setRole(widget.userId, _role);
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        final msg = e is ArgumentError ||
                e.toString().contains('uuid') ||
                e.toString().contains('22P02')
            ? 'This user\'s ID is not a valid UUID. Fix or remove the row in Supabase Dashboard (Table Editor > user_roles).'
            : e.toString();
        setState(() => _savingError = msg);
      }
    }
  }

  Future<void> _assignManagement(String businessId) async {
    final repo = BusinessManagersRepository();
    try {
      await repo.insert(businessId, widget.userId);
      if (mounted) {
        setState(
          () => _managedBusinessIds = [..._managedBusinessIds, businessId],
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _removeManagement(String businessId) async {
    final repo = BusinessManagersRepository();
    try {
      await repo.delete(businessId, widget.userId);
      if (mounted) {
        setState(
          () => _managedBusinessIds = _managedBusinessIds
              .where((id) => id != businessId)
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  static final _inputDecoration = InputDecoration(
    filled: true,
    fillColor: AppTheme.specOffWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.specNavy, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final availableBusinesses = _allBusinesses
        .where((b) => !_managedBusinessIds.contains(b.id))
        .toList();
    final planValue = () {
      final planId = _subscription?.planId ?? '';
      if (planId.isEmpty) return '';
      return _userPlans.any((p) => p.id == planId) ? planId : '';
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.specNavy.withValues(alpha: 0.08),
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: AppTheme.specNavy,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppOutlinedButton(
                onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                icon: _uploadingAvatar
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  _uploadingAvatar ? 'Uploading...' : 'Upload avatar',
                ),
              ),
            ),
          ],
        ),
        if (widget.initialEmail.isNotEmpty) ...[
          AdminDetailLabel('Email'),
          Text(
            widget.initialEmail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        AdminDetailLabel('Display name'),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration.copyWith(labelText: 'Display name'),
          textCapitalization: TextCapitalization.words,
        ),
        AdminDetailLabel('Role'),
        DropdownButtonFormField<String>(
          initialValue: _role,
          decoration: _inputDecoration.copyWith(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(
              value: 'business_owner',
              child: Text('Business owner'),
            ),
            DropdownMenuItem(value: 'user', child: Text('User')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _role = v);
          },
        ),
        AdminDetailLabel('User plan'),
        DropdownButtonFormField<String>(
          initialValue: (planValue == '' || _userPlans.any((p) => p.id == planValue))
              ? planValue
              : '',
          decoration: _inputDecoration.copyWith(labelText: 'Assign plan'),
          items: [
            const DropdownMenuItem(value: '', child: Text('None')),
            ..._userPlans.map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Text('${p.name} (${p.tier})'),
              ),
            ),
          ],
          onChanged: (v) => _assignPlan(v),
        ),
        AdminDetailLabel('Management'),
        if (_loading) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            ),
          ),
        ] else ...[
          ..._managedBusinessIds.map((id) {
            final businessById = {for (var b in _allBusinesses) b.id: b};
            final name = businessById[id]?.name ?? id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.specRed,
                      size: 22,
                    ),
                    onPressed: () => _removeManagement(id),
                    tooltip: 'Remove management',
                  ),
                ],
              ),
            );
          }),
          if (availableBusinesses.isEmpty) ...[
            Text(
              'No other businesses to assign.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            _AssignBusinessDropDown(
              businesses: availableBusinesses,
              onAssign: (businessId) async {
                await _assignManagement(businessId);
              },
            ),
          ],
        ],
        if (_savingError != null) ...[
          const SizedBox(height: 12),
          Text(
            _savingError!,
            style: TextStyle(color: colorScheme.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        AppSecondaryButton(
          onPressed: _saveNameAndRole,
          child: const Text('Save name & role'),
        ),
        const SizedBox(height: 12),
        AppOutlinedButton(
          onPressed: _downgradeUser,
          child: const Text('Downgrade to User (remove plan)'),
        ),
        const SizedBox(height: 8),
        AppDangerOutlinedButton(
          onPressed: _deleteUser,
          child: const Text('Remove user from app'),
        ),
      ],
    );
  }
}

class _AssignBusinessDropDown extends StatefulWidget {
  const _AssignBusinessDropDown({
    required this.businesses,
    required this.onAssign,
  });

  final List<Business> businesses;
  final Future<void> Function(String businessId) onAssign;

  @override
  State<_AssignBusinessDropDown> createState() =>
      _AssignBusinessDropDownState();
}

class _AssignBusinessDropDownState extends State<_AssignBusinessDropDown> {
  String? _selectedId;
  bool _adding = false;

  @override
  void didUpdateWidget(covariant _AssignBusinessDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final list = widget.businesses;
    if (list.isNotEmpty &&
        (_selectedId == null || !list.any((b) => b.id == _selectedId))) {
      _selectedId = list.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.businesses;
    if (list.isEmpty) return const SizedBox.shrink();
    final value = list.any((b) => b.id == _selectedId)
        ? _selectedId!
        : list.first.id;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: 'Assign to business',
              filled: true,
              fillColor: AppTheme.specOffWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: list
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedId = v),
          ),
        ),
        const SizedBox(width: 8),
        AppSecondaryButton(
          onPressed: _adding
              ? null
              : () async {
                  final id = _selectedId ?? list.first.id;
                  setState(() => _adding = true);
                  await widget.onAssign(id);
                  if (mounted) {
                    setState(() => _adding = false);
                  }
                },
          child: _adding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
