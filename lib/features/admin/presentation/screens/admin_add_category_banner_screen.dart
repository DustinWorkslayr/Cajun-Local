import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/category_banner.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/data/repositories/category_banners_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: create or edit a category banner.
class AdminAddCategoryBannerScreen extends StatefulWidget {
  const AdminAddCategoryBannerScreen({super.key, this.initialBanner});

  /// When set, form is in edit mode (update instead of insert).
  final CategoryBanner? initialBanner;

  @override
  State<AdminAddCategoryBannerScreen> createState() => _AdminAddCategoryBannerScreenState();
}

class _AdminAddCategoryBannerScreenState extends State<AdminAddCategoryBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  List<BusinessCategory> _categories = [];
  bool _loading = true;
  BusinessCategory? _selectedCategory;
  bool _saving = false;
  String? _message;
  bool _success = false;
  bool _uploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage || _selectedCategory == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final url = await AppStorageService().uploadCategoryBanner(
        pathSegment: _selectedCategory!.id,
        bytes: bytes,
        extension: ext,
      );
      if (mounted) {
        _imageUrlController.text = url;
        setState(() => _uploadingImage = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final b = widget.initialBanner;
    if (b != null) _imageUrlController.text = b.imageUrl;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await CategoryRepository().listCategories();
    if (mounted) {
      final initial = widget.initialBanner;
      BusinessCategory? selected;
      if (list.isNotEmpty) {
        if (initial != null) {
          try {
            selected = list.firstWhere((c) => c.id == initial.categoryId);
          } catch (_) {
            selected = list.first;
          }
        } else {
          selected = list.first;
        }
      }
      setState(() {
        _categories = list;
        _loading = false;
        _selectedCategory = selected;
        if (initial != null && _imageUrlController.text.isEmpty) {
          _imageUrlController.text = initial.imageUrl;
        }
      });
    }
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initialBanner != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() {
        _message = 'Please select a category.';
        _success = false;
      });
      return;
    }
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final repo = CategoryBannersRepository();
      final categoryId = _selectedCategory!.id;
      final imageUrl = _imageUrlController.text.trim();
      if (_isEdit) {
        await repo.update(widget.initialBanner!.id, categoryId: categoryId, imageUrl: imageUrl);
      } else {
        await repo.insert(categoryId: categoryId, imageUrl: imageUrl);
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = _isEdit ? 'Banner updated.' : 'Banner created.';
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
          _isEdit ? 'Edit category banner' : 'Add category banner',
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                DropdownButtonFormField<BusinessCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCategory = c),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_rounded, size: 20),
                  label: Text(_uploadingImage ? 'Uploading...' : 'Upload image to category-banners bucket'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                    hintText: 'https://... or use Upload above',
                  ),
                  keyboardType: TextInputType.url,
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
                      : Text(_isEdit ? 'Save changes' : 'Create banner'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
