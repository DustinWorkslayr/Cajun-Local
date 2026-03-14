import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/categories/data/models/subcategory.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_section_card.dart';
import 'package:cajun_local/shared/widgets/business_amenities_editor.dart';
import 'package:cajun_local/features/my_listings/presentation/controllers/details_tab_controller.dart';
import 'package:cajun_local/features/businesses/data/models/business_image.dart';

class DetailsTab extends ConsumerStatefulWidget {
  const DetailsTab({
    super.key,
    required this.listingId,
    required this.onSaveRequested,
    required this.listing,
  });

  final String listingId;
  final VoidCallback onSaveRequested;
  final Business listing;

  @override
  ConsumerState<DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends ConsumerState<DetailsTab> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  String? _selectedCategoryId;
  String? _selectedParishId;
  final Set<String> _selectedServiceParishIds = {};
  final Set<String> _selectedSubcategoryIds = {};

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l.name);
    _addressController = TextEditingController(text: l.address ?? '');
    _phoneController = TextEditingController(text: l.phone ?? '');
    _websiteController = TextEditingController(text: l.website ?? '');
    _descriptionController = TextEditingController(text: l.description ?? '');
    _selectedCategoryId = l.categoryId;
    _selectedParishId = l.parish;
    // service parishes are handled via setBusinessParishes repository call, 
    // but initially we might want to sync if we have them in the business model or another call.
    // For now, syncing from state in build.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(detailsTabControllerProvider(widget.listingId).notifier).save(
          name: _nameController.text.trim(),
          tagline: _nameController.text.trim(), // Tagline used as name for now in some places
          categoryId: _selectedCategoryId,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          website: _websiteController.text.trim(),
          description: _descriptionController.text.trim(),
          parishId: _selectedParishId,
          serviceParishIds: [_selectedParishId!, ..._selectedServiceParishIds].whereType<String>().toList(),
          subcategoryIds: _selectedSubcategoryIds.toList(),
        );

    final state = ref.read(detailsTabControllerProvider(widget.listingId)).valueOrNull;
    if (state?.success == true) {
      setState(() => _isEditing = false);
      widget.onSaveRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final asyncState = ref.watch(detailsTabControllerProvider(widget.listingId));

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (state) {
        // Sync initial values from controller state if needed
        if (_selectedSubcategoryIds.isEmpty && state.initialSubcategoryIds.isNotEmpty) {
           _selectedSubcategoryIds.addAll(state.initialSubcategoryIds);
        }

        final selectedCat = state.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
        final subcategories = selectedCat?.subcategories ?? <Subcategory>[];
        final categoryBucket = selectedCat?.bucket;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Details',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: nav),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update your listing identity, location, and photos.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: nav.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  AppSecondaryButton(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            _IdentitySection(
              isEditing: _isEditing,
              nameController: _nameController,
              descriptionController: _descriptionController,
              selectedCategoryId: _selectedCategoryId,
              categories: state.categories,
              onCategoryChanged: (id) => setState(() {
                _selectedCategoryId = id;
                _selectedSubcategoryIds.clear();
              }),
              subcategoryIds: _selectedSubcategoryIds,
              onSubcategoryToggle: (id) => setState(() {
                if (_selectedSubcategoryIds.contains(id)) {
                  _selectedSubcategoryIds.remove(id);
                } else {
                  _selectedSubcategoryIds.add(id);
                }
              }),
              subcategories: subcategories,
              listingId: widget.listingId,
              categoryBucket: selectedCat?.bucket,
            ),
            
            const SizedBox(height: 20),
            
            _LocationSection(
              isEditing: _isEditing,
              addressController: _addressController,
              selectedParishId: _selectedParishId,
              parishes: state.parishes,
              onParishChanged: (id) => setState(() => _selectedParishId = id),
              serviceParishIds: _selectedServiceParishIds,
            ),

            const SizedBox(height: 20),

            _ContactSection(
              isEditing: _isEditing,
              phoneController: _phoneController,
              websiteController: _websiteController,
            ),

            const SizedBox(height: 20),

            _MediaSection(
              listingId: widget.listingId,
              logoUrl: state.businessRaw?.logoUrl,
              bannerUrl: state.businessRaw?.bannerUrl,
              galleryImages: state.galleryImages,
              uploadingGallery: state.uploadingGallery,
              saving: state.saving,
            ),

            const SizedBox(height: 32),

            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: state.saving ? null : () => setState(() => _isEditing = false),
                      child: Text('Cancel', style: TextStyle(color: nav.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      onPressed: state.saving ? null : _save,
                      label: Text(state.saving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({
    required this.isEditing,
    required this.nameController,
    required this.descriptionController,
    required this.selectedCategoryId,
    required this.categories,
    required this.onCategoryChanged,
    required this.subcategoryIds,
    required this.onSubcategoryToggle,
    required this.subcategories,
    required this.listingId,
    required this.categoryBucket,
  });

  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? selectedCategoryId;
  final List<BusinessCategory> categories;
  final ValueChanged<String?> onCategoryChanged;
  final Set<String> subcategoryIds;
  final ValueChanged<String> onSubcategoryToggle;
  final List<Subcategory> subcategories;
  final String listingId;
  final String? categoryBucket;

  @override
  Widget build(BuildContext context) {
    // Basic implementation - needs adaptation from the original file's _IdentitySection
    return AppSectionCard(
      title: 'Identity',
      icon: Icons.info_outline_rounded,
      children: [
        if (isEditing) ...[
          const SizedBox(height: 16),
          Text('Tags (optional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.specNavy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subcategories.map((s) {
              final selected = subcategoryIds.contains(s.id);
              return FilterChip(
                label: Text(s.name),
                selected: selected,
                onSelected: (_) => onSubcategoryToggle(s.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          BusinessAmenitiesEditor(
            businessId: listingId,
            categoryBucket: categoryBucket,
          ),
        ] else ...[
          _InfoRow(label: 'Name', value: nameController.text),
          _InfoRow(label: 'Category', value: categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => categories.first).name),
          if (subcategoryIds.isNotEmpty)
            _InfoRow(
              label: 'Tags',
              value: subcategories
                  .where((s) => subcategoryIds.contains(s.id))
                  .map((s) => s.name)
                  .join(', '),
            ),
          _InfoRow(label: 'Description', value: descriptionController.text),
        ],
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.isEditing,
    required this.addressController,
    required this.selectedParishId,
    required this.parishes,
    required this.onParishChanged,
    required this.serviceParishIds,
  });

  final bool isEditing;
  final TextEditingController addressController;
  final String? selectedParishId;
  final List<Parish> parishes;
  final ValueChanged<String?> onParishChanged;
  final Set<String> serviceParishIds;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Location',
      icon: Icons.location_on_rounded,
      children: [
        if (isEditing) ...[
          DropdownButtonFormField<String>(
            initialValue: selectedParishId,
            items: parishes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: onParishChanged,
            decoration: const InputDecoration(labelText: 'Primary Parish'),
          ),
          const SizedBox(height: 16),
          Text('Other parishes served (optional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.specNavy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parishes.map((p) {
              if (p.id == selectedParishId) return const SizedBox.shrink();
              final selected = serviceParishIds.contains(p.id);
              return FilterChip(
                label: Text(p.name),
                selected: selected,
                onSelected: (val) {
                   if (val) {
                     serviceParishIds.add(p.id);
                   } else {
                     serviceParishIds.remove(p.id);
                   }
                },
              );
            }).toList(),
          ),
        ] else ...[
          _InfoRow(label: 'Address', value: addressController.text),
          _InfoRow(label: 'Parish', value: parishes.firstWhere((p) => p.id == selectedParishId, orElse: () => parishes.first).name),
          if (serviceParishIds.isNotEmpty)
             _InfoRow(label: 'Also serves', value: parishes.where((p) => serviceParishIds.contains(p.id)).map((p) => p.name).join(', ')),
        ],
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.isEditing,
    required this.phoneController,
    required this.websiteController,
  });

  final bool isEditing;
  final TextEditingController phoneController;
  final TextEditingController websiteController;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Contact',
      icon: Icons.contact_phone_rounded,
      children: [
        if (isEditing) ...[
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: websiteController,
            decoration: const InputDecoration(labelText: 'Website'),
            keyboardType: TextInputType.url,
          ),
        ] else ...[
          _InfoRow(label: 'Phone', value: phoneController.text),
          _InfoRow(label: 'Website', value: websiteController.text),
        ],
      ],
    );
  }
}

class _MediaSection extends ConsumerWidget {
  const _MediaSection({
    required this.listingId,
    required this.logoUrl,
    required this.bannerUrl,
    required this.galleryImages,
    required this.uploadingGallery,
    required this.saving,
  });

  final String listingId;
  final String? logoUrl;
  final String? bannerUrl;
  final List<BusinessImage> galleryImages;
  final bool uploadingGallery;
  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSectionCard(
      title: 'Media',
      icon: Icons.photo_library_rounded,
      children: [
        Text('Logo & Banner', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.specNavy)),
        const SizedBox(height: 8),
        // Simplified for now
        Row(
          children: [
             if (logoUrl != null) Image.network(logoUrl!, width: 50, height: 50),
             const SizedBox(width: 16),
             AppSecondaryButton(
               onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                  if (result != null) {
                    ref.read(detailsTabControllerProvider(listingId).notifier).uploadImage(
                      bytes: result.files.first.bytes!,
                      extension: result.files.first.extension ?? 'jpg',
                      type: 'logo',
                    );
                  }
               },
               label: const Text('Upload Logo'),
             ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.specNavy)),
        const SizedBox(height: 8),
        if (uploadingGallery) const LinearProgressIndicator(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...galleryImages.map((img) => Stack(
              children: [
                Image.network(img.url, width: 80, height: 80, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => ref.read(detailsTabControllerProvider(listingId).notifier).deleteGalleryImage(img.id),
                  ),
                ),
              ],
            )),
            IconButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                if (result != null) {
                  ref.read(detailsTabControllerProvider(listingId).notifier).uploadImage(
                    bytes: result.files.first.bytes!,
                    extension: result.files.first.extension ?? 'jpg',
                    type: 'gallery',
                  );
                }
              },
              icon: const Icon(Icons.add_a_photo),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
