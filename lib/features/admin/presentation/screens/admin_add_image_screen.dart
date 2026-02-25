import 'package:file_picker/file_picker.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/services/business_images_storage_service.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Add a business image by uploading to the business-images bucket.
/// [initialBusinessId] pre-selects the business when opening from listing edit.
class AdminAddImageScreen extends StatefulWidget {
  const AdminAddImageScreen({super.key, this.initialBusinessId});

  final String? initialBusinessId;

  @override
  State<AdminAddImageScreen> createState() => _AdminAddImageScreenState();
}

class _AdminAddImageScreenState extends State<AdminAddImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sortOrderController = TextEditingController(text: '0');
  List<Business> _businesses = [];
  bool _loading = true;
  Business? _selectedBusiness;
  List<BusinessImage> _images = [];
  bool _imagesLoading = false;
  String? _uploadedUrl;
  bool _uploading = false;
  bool _saving = false;
  String? _message;
  bool _success = false;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    final list = await BusinessRepository().listForAdmin();
    if (mounted) {
      setState(() {
        _businesses = list;
        _loading = false;
        if (list.isNotEmpty) {
          if (widget.initialBusinessId != null) {
            final match = list.where((b) => b.id == widget.initialBusinessId);
            _selectedBusiness = match.isEmpty ? list.first : match.first;
          } else {
            _selectedBusiness ??= list.first;
          }
        }
      });
      if (_selectedBusiness != null) _loadImages();
    }
  }

  Future<void> _loadImages() async {
    if (_selectedBusiness == null) return;
    setState(() => _imagesLoading = true);
    final list = await BusinessImagesRepository().listForBusiness(_selectedBusiness!.id);
    if (mounted) {
      setState(() {
        _images = list;
        _imagesLoading = false;
        _sortOrderController.text = '${list.length}';
      });
    }
  }

  @override
  void dispose() {
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    if (_selectedBusiness == null) {
      setState(() {
        _message = 'Select a business first.';
        _success = false;
      });
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        setState(() {
          _message = 'Could not read file. Use "withData" or try another image.';
          _success = false;
        });
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() {
      _message = null;
      _uploading = true;
    });
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: _selectedBusiness!.id,
        type: 'gallery',
        bytes: bytes,
        extension: ext,
      );
      if (mounted) {
        setState(() {
          _uploadedUrl = url;
          _uploading = false;
          _sortOrderController.text = '${_images.length}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
          _success = false;
          _uploading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      setState(() {
        _message = 'Please select a business.';
        _success = false;
      });
      return;
    }
    if (_uploadedUrl == null) {
      setState(() {
        _message = 'Upload an image first.';
        _success = false;
      });
      return;
    }
    setState(() {
      _message = null;
      _saving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = AppDataScope.of(context).authRepository;
      final uid = auth.currentUserId;
      final isAdmin = uid != null && await auth.isAdmin();
      await BusinessImagesRepository().insert(
        businessId: _selectedBusiness!.id,
        url: _uploadedUrl!,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? _images.length,
        approvedBy: isAdmin ? uid : null,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _loadImages();
      setState(() {
        _uploadedUrl = null;
        _sortOrderController.text = '${_images.length}';
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isAdmin ? 'Image added (approved).' : 'Image added. It will appear after admin approval.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _success = false;
        _message = e.toString();
      });
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<BusinessImage>.from(_images);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    final orderedIds = reordered.map((e) => e.id).toList();
    setState(() => _savingOrder = true);
    try {
      await BusinessImagesRepository().updateSortOrder(orderedIds);
      if (mounted) {
        setState(() {
          _images = reordered;
          _savingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: nav,
        ),
        title: Text(
          'Add image',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: AppLayout.constrainSection(
          context,
          Form(
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
                  // When opened from a specific listing, don't show business selector.
                  if (widget.initialBusinessId == null) ...[
                    DropdownButtonFormField<Business>(
                      initialValue: _selectedBusiness,
                      decoration: InputDecoration(
                        labelText: 'Business',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      items: _businesses
                          .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                          .toList(),
                      onChanged: (b) {
                        setState(() {
                          _selectedBusiness = b;
                          _uploadedUrl = null;
                          _images = [];
                        });
                        if (b != null) _loadImages();
                      },
                      validator: (v) => v == null ? 'Select a business' : null,
                    ),
                  ] else if (_selectedBusiness != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _selectedBusiness!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: nav,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Add new photo card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.specWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add new photo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: nav,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppOutlinedButton(
                          onPressed: _uploading ? null : _pickAndUpload,
                          icon: _uploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: nav),
                                )
                              : const Icon(Icons.add_photo_alternate_rounded, size: 22),
                          label: Text(_uploading ? 'Uploading...' : 'Choose image to upload'),
                        ),
                        if (_uploadedUrl != null) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _uploadedUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 120,
                                color: nav.withValues(alpha: 0.1),
                                child: const Center(child: Icon(Icons.broken_image_outlined)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sort order for this image (0 = first). New image will be added at this position.',
                            style: theme.textTheme.bodySmall?.copyWith(color: sub),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _sortOrderController,
                            decoration: InputDecoration(
                              labelText: 'Sort order',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppTheme.specWhite,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            onPressed: _saving ? null : _submit,
                            expanded: false,
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Add image'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Existing images – drag to reorder
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.specWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Photo order',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: nav,
                              ),
                            ),
                            if (_savingOrder) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: nav),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drag to reorder. Order is saved automatically.',
                          style: theme.textTheme.bodySmall?.copyWith(color: sub),
                        ),
                        const SizedBox(height: 12),
                        if (_imagesLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_images.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No photos yet. Add one above.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: _images.length,
                            onReorder: _onReorder,
                            itemBuilder: (context, index) {
                              final img = _images[index];
                              return ReorderableDragStartListener(
                                key: ValueKey(img.id),
                                index: index,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.specOffWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: nav.withValues(alpha: 0.15)),
                                  ),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        img.url,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 56,
                                          height: 56,
                                          color: nav.withValues(alpha: 0.1),
                                          child: const Icon(Icons.image_not_supported_outlined),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Photo ${index + 1}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: nav,
                                      ),
                                    ),
                                    subtitle: img.status != 'approved'
                                        ? Text(
                                            img.status,
                                            style: theme.textTheme.bodySmall?.copyWith(color: sub),
                                          )
                                        : null,
                                    trailing: Icon(Icons.drag_handle_rounded, color: sub),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _success ? Colors.green : AppTheme.specRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
