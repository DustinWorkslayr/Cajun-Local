import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/admin/data/models/parish.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/admin/data/repositories/parish_repository.dart';
import 'package:cajun_local/core/data/services/app_storage_service.dart';
import 'package:cajun_local/core/data/services/storage_upload_constants.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// Admin: create or edit a blog post. Body is edited with a rich text (Quill) editor and stored as HTML.
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
  late final quill.QuillController _quillController;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  String _status = 'draft';
  bool _saving = false;
  String? _message;
  bool _success = false;
  String? _coverImageUrl;
  bool _uploadingCover = false;
  List<Parish> _parishes = [];
  bool _allParishes = true;
  Set<String> _selectedParishIds = {};

  static const List<String> _validStatuses = ['draft', 'pending', 'approved', 'rejected', 'published'];

  @override
  void initState() {
    super.initState();
    _quillController = _createQuillController();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _slugController.text = widget.post!.slug;
      final s = widget.post!.status;
      _status = _validStatuses.contains(s) ? s : 'draft';
      _coverImageUrl = widget.post!.coverImageUrl;
      _allParishes = widget.post!.isAllParishes;
      _selectedParishIds = widget.post!.parishIds != null ? widget.post!.parishIds!.toSet() : {};
    }
    _loadParishes();
  }

  quill.QuillController _createQuillController() {
    quill.Document document;
    final html = widget.post?.content?.trim() ?? '';
    if (html.isNotEmpty) {
      try {
        final delta = HtmlToDelta().convert(html, transformTableAsEmbed: false);
        document = quill.Document.fromJson(delta.toJson());
      } catch (_) {
        document = quill.Document();
      }
    } else {
      document = quill.Document();
    }
    return quill.QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
  }

  Future<void> _loadParishes() async {
    final list = await ParishRepository().listParishes();
    if (mounted) setState(() => _parishes = list);
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
      final url = await AppStorageService().uploadBlogImage(pathSegment: pathSegment, bytes: bytes, extension: ext);
      if (mounted)
        setState(() {
          _coverImageUrl = url;
          _uploadingCover = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _quillDeltaToHtml() {
    final delta = _quillController.document.toDelta();
    final ops = delta.toJson();
    if (ops.isEmpty) return '';
    final converter = QuillDeltaToHtmlConverter(ops, ConverterOptions.forEmail());
    return converter.convert().trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final contentHtml = _quillDeltaToHtml();
      final repo = BlogPostsRepository();
      final parishIds = _allParishes ? null : _selectedParishIds.toList();
      if (widget.post != null) {
        await repo.update(
          id: widget.post!.id,
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          content: contentHtml.isEmpty ? null : contentHtml,
          status: _status,
          coverImageUrl: _coverImageUrl,
          parishIds: parishIds,
        );
      } else {
        await repo.insert(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          content: contentHtml.isEmpty ? null : contentHtml,
          status: _status,
          coverImageUrl: _coverImageUrl,
          parishIds: parishIds,
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
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
              _SectionLabel(title: 'Parish visibility'),
              Text(
                'Choose which parishes will see this post. "All parishes" shows it to everyone.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _allParishes,
                onChanged: (v) => setState(() {
                  _allParishes = v ?? true;
                  if (_allParishes) _selectedParishIds = {};
                }),
                title: const Text('All parishes'),
                subtitle: Text(
                  _allParishes ? 'Post will appear for every user' : 'Select specific parishes below',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.specGold,
              ),
              if (!_allParishes) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _parishes.map((p) {
                    final selected = _selectedParishIds.contains(p.id);
                    return FilterChip(
                      label: Text(p.name),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedParishIds.add(p.id);
                        } else {
                          _selectedParishIds.remove(p.id);
                        }
                      }),
                      selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.specNavy,
                    );
                  }).toList(),
                ),
              ],
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
              _SectionLabel(title: 'Content'),
              Text(
                'Use the toolbar to format text. Content is saved as HTML and rendered on the post.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController,
                      config: const quill.QuillSimpleToolbarConfig(
                        showAlignmentButtons: true,
                        showBackgroundColorButton: false,
                        showFontFamily: false,
                        showFontSize: false,
                        showColorButton: false,
                        showSearchButton: false,
                        showSubscript: false,
                        showSuperscript: false,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 280,
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: const quill.QuillEditorConfig(
                          placeholder: 'Write your post content…',
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
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
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
      ),
    );
  }
}
