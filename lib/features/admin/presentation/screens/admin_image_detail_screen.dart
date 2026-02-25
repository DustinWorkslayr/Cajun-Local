import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';

class AdminImageDetailScreen extends StatefulWidget {
  const AdminImageDetailScreen({super.key, required this.imageId});

  final String imageId;

  @override
  State<AdminImageDetailScreen> createState() => _AdminImageDetailScreenState();
}

class _AdminImageDetailScreenState extends State<AdminImageDetailScreen> {
  BusinessImage? _image;
  String? _businessName;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BusinessImagesRepository();
    final img = await repo.getByIdForAdmin(widget.imageId);
    if (!mounted) return;
    if (img == null) {
      setState(() {
        _image = null;
        _loading = false;
        _error = 'Image not found';
      });
      return;
    }
    final b = await BusinessRepository().getByIdForAdmin(img.businessId);
    if (mounted) {
      setState(() {
        _image = img;
        _businessName = b?.name;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = BusinessImagesRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.imageId, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'image_approved' : 'image_rejected',
      userId: uid,
      targetTable: 'business_images',
      targetId: widget.imageId,
    );
    if (status == 'approved' && _image != null) {
      final businessRepo = BusinessRepository();
      final userId = await BusinessManagersRepository().getFirstManagerUserId(_image!.businessId) ??
          await businessRepo.getCreatedBy(_image!.businessId);
      if (userId != null) {
        final profile = await AuthRepository().getProfileForAdmin(userId);
        final to = profile?.email?.trim();
        if (to != null && to.isNotEmpty) {
          await SendEmailService().send(
            to: to,
            template: 'image_approved',
            variables: {
              'display_name': profile?.displayName ?? to,
              'email': to,
              'business_name': _businessName ?? _image!.businessId,
            },
          );
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status set to $status')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Business image')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: theme.textTheme.bodyLarge))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_image!.url.isNotEmpty)
                        Image.network(_image!.url, height: 200, fit: BoxFit.cover),
                      const SizedBox(height: 16),
                      _DetailRow(label: 'Status', value: _image!.status),
                      _DetailRow(label: 'Business', value: _businessName ?? _image!.businessId),
                      _DetailRow(label: 'URL', value: _image!.url),
                      const SizedBox(height: 24),
                      if (_image!.status == 'pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _updateStatus('approved'),
                                icon: const Icon(Icons.check_rounded, size: 20),
                                label: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus('rejected'),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                label: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
