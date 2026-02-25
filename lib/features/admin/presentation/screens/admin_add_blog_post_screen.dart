import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: create or edit a blog post. Body is edited as raw HTML; you provide the full HTML content.
class AdminAddBlogPostScreen extends StatefulWidget {
  const AdminAddBlogPostScreen({super.key, this.post});

  /// When set, edit mode: load post and save updates (if repo supports update).
  final BlogPost? post;

  @override
  State<AdminAddBlogPostScreen> createState() => _AdminAddBlogPostScreenState();
}

class _AdminAddBlogPostScreenState extends State<AdminAddBlogPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _bodyController = TextEditingController();
  String _status = 'draft';
  bool _saving = false;
  String? _message;
  bool _success = false;
  String? _coverImageUrl;
  bool _uploadingCover = false;

  static const List<String> _validStatuses = ['draft', 'pending', 'approved', 'rejected', 'published'];

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _slugController.text = widget.post!.slug;
      final s = widget.post!.status;
      _status = _validStatuses.contains(s) ? s : 'draft';
      _coverImageUrl = widget.post!.coverImageUrl;
      _bodyController.text = widget.post!.content ?? '';
    }
  }

  Future<void> _pickAndUploadBanner() async {
    if (_uploadingCover) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploadingCover = true);
    try {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final pathSegment = _slugController.text.trim().isEmpty ? 'blog' : _slugController.text.trim();
      final url = await AppStorageService().uploadBlogImage(
        pathSegment: pathSegment,
        bytes: bytes,
        extension: ext,
      );
      if (mounted) setState(() { _coverImageUrl = url; _uploadingCover = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
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
      final contentHtml = _bodyController.text.trim();
      final repo = BlogPostsRepository();
      if (widget.post != null) {
        await repo.update(
          id: widget.post!.id,
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          content: contentHtml.isEmpty ? null : contentHtml,
          status: _status,
          coverImageUrl: _coverImageUrl,
        );
      } else {
        await repo.insert(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          content: contentHtml.isEmpty ? null : contentHtml,
          status: _status,
          coverImageUrl: _coverImageUrl,
        );
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = widget.post != null ? 'Post updated.' : 'Post created.';
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
    final isEdit = widget.post != null;

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
          isEdit ? 'Edit post' : 'New post',
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
                  hintText: 'Give your post a clear title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'URL slug',
                  hintText: 'e.g. my-first-post',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: 'Cover image'),
              if (_coverImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _coverImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholderBanner(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              AppOutlinedButton(
                onPressed: _uploadingCover ? null : _pickAndUploadBanner,
                icon: _uploadingCover
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_rounded, size: 20),
                label: Text(_coverImageUrl != null ? 'Change image' : 'Add cover image'),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: 'Status'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Content (HTML)'),
              Text(
                'Paste or type your full HTML content below. It will be stored and rendered as-is on the post.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bodyController,
                maxLines: 24,
                minLines: 12,
                decoration: const InputDecoration(
                  hintText: '<p>Your content here…</p>',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: AppTheme.specNavy,
                ),
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
                    : Text(isEdit ? 'Save changes' : 'Create post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.specNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.3)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.specNavy,
        ),
      ),
    );
  }
}

