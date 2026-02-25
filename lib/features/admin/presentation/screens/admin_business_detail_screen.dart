import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/business_image.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/data/models/business_plan.dart';
import 'package:my_app/core/data/repositories/business_plans_repository.dart';
import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/models/menu_item.dart';
import 'package:my_app/core/data/models/menu_section.dart';
import 'package:my_app/core/data/repositories/business_images_repository.dart';
import 'package:my_app/core/data/repositories/business_managers_repository.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/models/parish.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/parish_repository.dart';
import 'package:my_app/core/data/services/send_email_service.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_empty_state.dart';
import 'package:my_app/shared/widgets/app_loader.dart';
import 'package:my_app/shared/widgets/business_hours_editor.dart';
import 'package:my_app/shared/widgets/business_links_editor.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/menu_repository.dart';
import 'package:my_app/core/data/services/business_images_storage_service.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/core/data/models/business_event.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_deal_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_deal_detail_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/create_business_item_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/event_detail_screen.dart';

const double _cardRadius = 16;

class AdminBusinessDetailScreen extends StatefulWidget {
  const AdminBusinessDetailScreen({super.key, required this.businessId});

  final String businessId;

  @override
  State<AdminBusinessDetailScreen> createState() => _AdminBusinessDetailScreenState();
}

class _AdminBusinessDetailScreenState extends State<AdminBusinessDetailScreen> {
  Business? _business;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BusinessRepository();
    final b = await repo.getByIdForAdmin(widget.businessId);
    if (mounted) {
      setState(() {
        _business = b;
        _loading = false;
        if (b == null) _error = 'Business not found';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = BusinessRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.businessId, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'business_approved' : 'business_rejected',
      userId: uid,
      targetTable: 'businesses',
      targetId: widget.businessId,
    );
    if (status == 'approved' && _business != null) {
      final userId = await BusinessManagersRepository().getFirstManagerUserId(widget.businessId) ??
          await repo.getCreatedBy(widget.businessId);
      if (userId != null) {
        final profile = await AuthRepository().getProfileForAdmin(userId);
        final to = profile?.email?.trim();
        if (to != null && to.isNotEmpty) {
          await SendEmailService().send(
            to: to,
            template: 'business_approved',
            variables: {
              'display_name': profile?.displayName ?? to,
              'email': to,
              'business_name': _business!.name,
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

    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          foregroundColor: AppTheme.specNavy,
          title: const Text('Business', style: TextStyle(color: AppTheme.specNavy)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _business == null) {
      return Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          foregroundColor: AppTheme.specNavy,
        ),
        body: Center(
          child: Text(
            _error ?? 'Not found',
            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
          ),
        ),
      );
    }

    final business = _business!;
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppTheme.specNavy,
          title: Text(
            business.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          bottom: TabBar(
            labelColor: AppTheme.specNavy,
            unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.6),
            indicatorColor: AppTheme.specGold,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline_rounded, size: 20), text: 'Overview'),
              Tab(icon: Icon(Icons.image_rounded, size: 20), text: 'Images'),
              Tab(icon: Icon(Icons.view_list_rounded, size: 20), text: 'Menu'),
              Tab(icon: Icon(Icons.local_offer_rounded, size: 20), text: 'Deals'),
              Tab(icon: Icon(Icons.event_rounded, size: 20), text: 'Events'),
              Tab(icon: Icon(Icons.schedule_rounded, size: 20), text: 'Hours & links'),
              Tab(icon: Icon(Icons.card_membership_rounded, size: 20), text: 'Subscription'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              business: business,
              onSaved: _load,
              onStatusChanged: _updateStatus,
            ),
            _ImagesTab(businessId: widget.businessId, businessName: business.name),
            _MenuTab(businessId: widget.businessId),
            _DealsTab(businessId: widget.businessId, businessName: business.name),
            _AdminEventsTab(businessId: widget.businessId, businessName: business.name),
            _HoursAndLinksTab(businessId: widget.businessId),
            _SubscriptionTab(businessId: widget.businessId, onUpdated: _load),
          ],
        ),
      ),
    );
  }
}

/// White card with home-theme shadow.
class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

// --- Overview tab: edit info + status ---

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({
    required this.business,
    required this.onSaved,
    required this.onStatusChanged,
  });

  final Business business;
  final VoidCallback onSaved;
  final Future<void> Function(String status) onStatusChanged;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;

  List<BusinessCategory> _categories = [];
  List<Subcategory> _subcategories = [];
  BusinessCategory? _selectedCategory;
  Set<String> _selectedSubcategoryIds = {};
  bool _categoriesLoading = true;
  bool _subcategoriesLoading = false;

  List<Parish> _parishes = [];
  bool _parishesLoading = true;
  String? _selectedPrimaryParishId;
  Set<String> _selectedServiceParishIds = {};

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _nameController = TextEditingController(text: b.name);
    _addressController = TextEditingController(text: b.address ?? '');
    _cityController = TextEditingController(text: b.city ?? '');
    _stateController = TextEditingController(text: b.state ?? '');
    _phoneController = TextEditingController(text: b.phone ?? '');
    _websiteController = TextEditingController(text: b.website ?? '');
    _descriptionController = TextEditingController(text: b.description ?? '');
    _selectedPrimaryParishId = b.parish?.trim().isEmpty == true ? null : b.parish;
    _loadCategoryData();
    _loadParishesAndServiceAreas();
  }

  Future<void> _loadParishesAndServiceAreas() async {
    setState(() => _parishesLoading = true);
    try {
      final repo = BusinessRepository();
      final parishRepo = ParishRepository();
      final list = await parishRepo.listParishes();
      final serviceIds = await repo.getBusinessParishIds(widget.business.id);
      if (!mounted) return;
      setState(() {
        _parishes = list;
        _parishesLoading = false;
        _selectedServiceParishIds = serviceIds.toSet();
      });
    } catch (_) {
      if (mounted) setState(() => _parishesLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant _OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) return;
    if (oldWidget.business.categoryId != widget.business.categoryId ||
        oldWidget.business.name != widget.business.name) {
      _syncCategoryFromBusiness();
    }
  }

  Future<void> _loadCategoryData() async {
    setState(() => _categoriesLoading = true);
    try {
      final categories = await CategoryRepository().listCategories();
      if (!mounted) return;
      final categoryId = widget.business.categoryId;
      BusinessCategory? selected;
      if (categoryId.isNotEmpty) {
        try {
          selected = categories.firstWhere((c) => c.id == categoryId);
        } catch (_) {}
      }
      setState(() {
        _categories = categories;
        _selectedCategory = selected;
        _categoriesLoading = false;
      });
      await _loadSubcategoriesForCurrentCategory();
      if (!mounted) return;
      final currentIds = await CategoryRepository().getSubcategoryIdsForBusiness(widget.business.id);
      if (mounted) {
        setState(() {
          _selectedSubcategoryIds = currentIds.toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _syncCategoryFromBusiness() {
    if (_categories.isEmpty) return;
    final categoryId = widget.business.categoryId;
    BusinessCategory? selected;
    if (categoryId.isNotEmpty) {
      try {
        selected = _categories.firstWhere((c) => c.id == categoryId);
      } catch (_) {}
    }
    setState(() => _selectedCategory = selected);
    _loadSubcategoriesForCurrentCategory();
  }

  Future<void> _loadSubcategoriesForCurrentCategory() async {
    final category = _selectedCategory;
    if (category == null) {
      setState(() {
        _subcategories = [];
        _subcategoriesLoading = false;
      });
      return;
    }
    setState(() => _subcategoriesLoading = true);
    try {
      final list = await CategoryRepository().listSubcategories(categoryId: category.id);
      if (!mounted) return;
      final validIds = list.map((s) => s.id).toSet();
      setState(() {
        _subcategories = list;
        _subcategoriesLoading = false;
        _selectedSubcategoryIds = _selectedSubcategoryIds.intersection(validIds);
      });
    } catch (_) {
      if (mounted) setState(() => _subcategoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadLogo() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() => _uploadingLogo = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.business.id,
        type: 'logo',
        bytes: bytes,
        extension: ext,
        isAdminUpload: true,
      );
      await BusinessRepository().updateBusiness(widget.business.id, logoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo updated.')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _uploadBanner() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    setState(() => _uploadingBanner = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.business.id,
        type: 'banner',
        bytes: bytes,
        extension: ext,
        isAdminUpload: true,
      );
      await BusinessRepository().updateBusiness(widget.business.id, bannerUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner updated.')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final businessRepo = BusinessRepository();
      await businessRepo.updateBusiness(
        widget.business.id,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        categoryId: _selectedCategory?.id,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        parish: _selectedPrimaryParishId?.trim().isEmpty == true ? null : _selectedPrimaryParishId,
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      await businessRepo.setBusinessSubcategories(
        widget.business.id,
        _selectedSubcategoryIds.toList(),
      );
      final serviceOnly = _selectedServiceParishIds
          .where((id) => id != _selectedPrimaryParishId)
          .toList();
      await businessRepo.setBusinessParishes(widget.business.id, serviceOnly);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic info',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 16),
                _LabelledField(label: 'Name', controller: _nameController, border: border, required: true),
                const SizedBox(height: 12),
                _LabelledField(label: 'Description', controller: _descriptionController, border: border, maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category & subcategories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 12),
                if (_categoriesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else ...[
                  DropdownButtonFormField<BusinessCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: border,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    hint: const Text('Select category'),
                    items: _categories
                        .map((c) => DropdownMenuItem<BusinessCategory>(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (BusinessCategory? c) {
                      setState(() => _selectedCategory = c);
                      _loadSubcategoriesForCurrentCategory();
                    },
                  ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Subcategories (optional)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_subcategoriesLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (_subcategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No subcategories for this category.',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subcategories.map((s) {
                          final selected = _selectedSubcategoryIds.contains(s.id);
                          return FilterChip(
                            label: Text(s.name),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedSubcategoryIds = _selectedSubcategoryIds.difference({s.id});
                                } else {
                                  _selectedSubcategoryIds = {..._selectedSubcategoryIds, s.id};
                                }
                              });
                            },
                            selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                            checkmarkColor: AppTheme.specNavy,
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logo (admin)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.business.logoUrl!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 80,
                        width: 80,
                        color: AppTheme.specNavy.withValues(alpha: 0.1),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppOutlinedButton(
                  onPressed: _uploadingLogo ? null : _uploadLogo,
                  icon: _uploadingLogo
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                        )
                      : const Icon(Icons.upload_rounded, size: 20),
                  label: Text(_uploadingLogo ? 'Uploading...' : 'Upload logo (admin)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banner (admin)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin-set listing banner/cover (hero on detail page). Separate from owner-uploaded banner.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.business.bannerUrl != null && widget.business.bannerUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.business.bannerUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 160,
                        width: double.infinity,
                        color: AppTheme.specNavy.withValues(alpha: 0.1),
                        child: const Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppOutlinedButton(
                  onPressed: _uploadingBanner ? null : _uploadBanner,
                  icon: _uploadingBanner
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                        )
                      : const Icon(Icons.image_rounded, size: 20),
                  label: Text(_uploadingBanner ? 'Uploading...' : 'Upload banner (admin)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location & contact',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 16),
                _LabelledField(label: 'Address', controller: _addressController, border: border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _LabelledField(label: 'City', controller: _cityController, border: border)),
                    const SizedBox(width: 12),
                    Expanded(child: _LabelledField(label: 'State', controller: _stateController, border: border)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Primary parish',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_parishesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _parishes.any((p) => p.id == _selectedPrimaryParishId) ? _selectedPrimaryParishId : null,
                    decoration: InputDecoration(
                      border: border,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    hint: const Text('Select parish'),
                    items: _parishes
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (String? id) => setState(() => _selectedPrimaryParishId = id),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Also serves these parishes (multi-select)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_parishesLoading)
                  const SizedBox.shrink()
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _parishes.map((p) {
                      final isPrimary = p.id == _selectedPrimaryParishId;
                      final selected = _selectedServiceParishIds.contains(p.id);
                      return FilterChip(
                        label: Text(p.name),
                        selected: selected,
                        onSelected: isPrimary
                            ? null
                            : (_) {
                                setState(() {
                                  if (selected) {
                                    _selectedServiceParishIds = _selectedServiceParishIds.difference({p.id});
                                  } else {
                                    _selectedServiceParishIds = {..._selectedServiceParishIds, p.id};
                                  }
                                });
                              },
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                        checkmarkColor: AppTheme.specNavy,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                _LabelledField(label: 'Phone', controller: _phoneController, border: border, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _LabelledField(label: 'Website', controller: _websiteController, border: border, keyboardType: TextInputType.url),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(widget.business.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.business.status,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _statusColor(widget.business.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.business.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          onPressed: _saving ? null : () => widget.onStatusChanged('approved'),
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDangerOutlinedButton(
                          onPressed: _saving ? null : () => widget.onStatusChanged('rejected'),
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
          const SizedBox(height: 20),
          AppPrimaryButton(
            onPressed: _saving ? null : _save,
            expanded: false,
            child: _saving
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return AppTheme.specRed;
      default:
        return AppTheme.specGold;
    }
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.controller,
    required this.border,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final InputBorder border;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
          decoration: InputDecoration(
            hintText: required ? 'Required' : 'Optional',
            hintStyle: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.4)),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// --- Images tab ---

class _ImagesTab extends StatefulWidget {
  const _ImagesTab({required this.businessId, required this.businessName});

  final String businessId;
  final String businessName;

  @override
  State<_ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<_ImagesTab> {
  List<BusinessImage> _images = [];
  bool _loading = true;
  bool _uploadingGallery = false;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BusinessImagesRepository().listForAdmin(businessId: widget.businessId);
    if (mounted) {
      setState(() {
        _images = list;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndAddImage() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }
    final ext = file.extension ?? 'jpg';
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    setState(() => _uploadingGallery = true);
    try {
      final url = await BusinessImagesStorageService().upload(
        businessId: widget.businessId,
        type: 'gallery',
        bytes: bytes,
        extension: ext,
      );
      await BusinessImagesRepository().insert(
        businessId: widget.businessId,
        url: url,
        sortOrder: _images.length,
        approvedBy: uid,
      );
      if (mounted) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added (approved).')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingGallery = false);
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

  Future<void> _approve(BusinessImage img) async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await BusinessImagesRepository().updateStatus(img.id, 'approved', approvedBy: uid);
    AuditLogRepository().insert(
      action: 'image_approved',
      userId: uid,
      targetTable: 'business_images',
      targetId: img.id,
    );
    final userId = await BusinessManagersRepository().getFirstManagerUserId(widget.businessId) ??
        await BusinessRepository().getCreatedBy(widget.businessId);
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
            'business_name': widget.businessName,
          },
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image approved')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    if (_loading) {
      return const Center(child: AppLoader.page());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add photos and drag to reorder. New photos go at the end.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          AppOutlinedButton(
            onPressed: _uploadingGallery ? null : _pickAndAddImage,
            icon: _uploadingGallery
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                  )
                : const Icon(Icons.add_photo_alternate_rounded),
            label: Text(_uploadingGallery ? 'Uploading...' : 'Add photo'),
          ),
          const SizedBox(height: 16),
          Text(
            'Gallery (${_images.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.specNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_images.isEmpty)
            _SpecCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Text(
                  'No images yet. Add a photo above.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SpecCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _savingOrder
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.drag_handle_rounded, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img.url,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) => Container(
                                width: 72,
                                height: 72,
                                color: AppTheme.specNavy.withValues(alpha: 0.1),
                                child: Icon(Icons.broken_image_outlined, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photo ${index + 1}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppTheme.specNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  img.status,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: img.status == 'approved' ? Colors.green : AppTheme.specGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  img.url,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (img.status != 'approved')
                            TextButton(
                              onPressed: () => _approve(img),
                              child: Text('Approve', style: TextStyle(color: AppTheme.specGold, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// --- Menu tab ---

class _MenuTab extends StatefulWidget {
  const _MenuTab({required this.businessId});

  final String businessId;

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  List<MenuSection> _sections = [];
  Map<String, List<MenuItem>> _itemsBySection = {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    try {
      final menuRepo = MenuRepository();
      final sections = await menuRepo.getSectionsForBusiness(widget.businessId);
      final Map<String, List<MenuItem>> itemsBySection = {};
      for (final s in sections) {
        itemsBySection[s.id] = await menuRepo.getItemsForSection(s.id);
      }
      if (mounted) {
        setState(() {
          _sections = sections;
          _itemsBySection = itemsBySection;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _sections = [];
          _itemsBySection = {};
          _loading = false;
          _errorMessage = e.toString();
        });
      }
      debugPrint('Menu tab load error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _addSection() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('New menu section'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Section name',
              hintText: 'e.g. Appetizers, Drinks',
            ),
            autofocus: true,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().isEmpty ? null : v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            AppPrimaryButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim().isEmpty ? null : c.text.trim()),
              expanded: false,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await MenuRepository().getOrCreateSectionId(widget.businessId, name);
    if (mounted) _load();
  }

  Future<void> _addItem(MenuSection section) async {
    final result = await showDialog<({String name, String? price, String? description})>(
      context: context,
      builder: (ctx) {
        final nameC = TextEditingController();
        final priceC = TextEditingController();
        final descC = TextEditingController();
        return AlertDialog(
          title: Text('Add item to ${section.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Item name *'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceC,
                  decoration: const InputDecoration(
                    labelText: 'Price (optional)',
                    hintText: 'e.g. 14.99',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final t = newValue.text;
                      if (t.split('.').length > 2) return oldValue;
                      return newValue;
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            AppPrimaryButton(
              onPressed: () {
                final n = nameC.text.trim();
                if (n.isEmpty) return;
                Navigator.of(ctx).pop((name: n, price: priceC.text.trim().isEmpty ? null : priceC.text.trim(), description: descC.text.trim().isEmpty ? null : descC.text.trim()));
              },
              expanded: false,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    await MenuRepository().insertItem(
      sectionId: section.id,
      name: result.name,
      price: result.price,
      description: result.description,
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    if (_loading) {
      return const Center(child: AppLoader.page());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding.left + padding.right),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.specNavy.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'Could not load menu',
                style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                onPressed: _load,
                expanded: false,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppOutlinedButton(
            onPressed: _addSection,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add section'),
          ),
          const SizedBox(height: 16),
          if (_sections.isEmpty)
            _SpecCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: AppEmptyState(
                message: 'No menu sections. Add a section to start adding items.',
                padding: EdgeInsets.zero,
              ),
            )
          else
            ..._sections.map((section) {
              final items = _itemsBySection[section.id] ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SpecCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              section.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specNavy,
                              ),
                            ),
                          ),
                          AppTextButton(
                            onPressed: () => _addItem(section),
                            useGold: true,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add item', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No items yet.',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
                          ),
                        )
                      else
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.specNavy,
                                          ),
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty)
                                          Text(
                                            item.description!,
                                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (item.price != null && item.price!.isNotEmpty)
                                    Text(
                                      item.price!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.specGold,
                                      ),
                                    ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// --- Deals tab ---

class _DealsTab extends StatefulWidget {
  const _DealsTab({required this.businessId, required this.businessName});

  final String businessId;
  final String businessName;

  @override
  State<_DealsTab> createState() => _DealsTabState();
}

class _DealsTabState extends State<_DealsTab> {
  List<Deal> _deals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DealsRepository().listForAdmin(businessId: widget.businessId);
    if (mounted) {
      setState(() {
        _deals = list;
        _loading = false;
      });
    }
  }

  Future<void> _addDeal() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAddDealScreen(initialBusinessId: widget.businessId),
      ),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    if (_loading) {
      return const Center(child: AppLoader.page());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            onPressed: _addDeal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add deal'),
          ),
          const SizedBox(height: 16),
          Text(
            'Deals (${_deals.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.specNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_deals.isEmpty)
            _SpecCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Text(
                  'No deals yet. Add a deal above.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.7)),
                ),
              ),
            )
          else
            ..._deals.map((deal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SpecCard(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminDealDetailScreen(dealId: deal.id),
                          ),
                        ).then((_) => _load());
                      },
                      borderRadius: BorderRadius.circular(_cardRadius),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  deal.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.specNavy,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (deal.status == 'approved' ? Colors.green : AppTheme.specGold).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  deal.status,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: deal.status == 'approved' ? Colors.green : AppTheme.specNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                            ],
                          ),
                          if (deal.description != null && deal.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              deal.description!,
                              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${deal.dealType} · ${deal.isActive == true ? "Active" : "Inactive"}',
                            style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// --- Events tab (admin): list events, add event, view detail with RSVP analytics ---

class _AdminEventsTab extends StatefulWidget {
  const _AdminEventsTab({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<_AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<_AdminEventsTab> {
  List<BusinessEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BusinessEventsRepository().listForBusiness(widget.businessId);
    if (mounted) {
      setState(() {
        _events = list;
        _loading = false;
      });
    }
  }

  Future<void> _addEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateEventScreen(listingId: widget.businessId),
      ),
    );
    if (mounted) _load();
  }

  static String _dateStr(DateTime d) => '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final nav = AppTheme.specNavy;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppOutlinedButton(
            onPressed: _addEvent,
            icon: const Icon(Icons.event_rounded),
            label: const Text('Add event'),
          ),
          const SizedBox(height: 16),
          Text(
            'Events (${_events.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: nav,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_events.isEmpty)
            _SpecCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Text(
                  'No events yet. Add an event above.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: nav.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            ..._events.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SpecCard(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EventDetailScreen(
                            eventId: e.id,
                            listingId: widget.businessId,
                          ),
                        ),
                      ).then((_) => _load());
                    },
                    borderRadius: BorderRadius.circular(_cardRadius),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: nav.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: nav,
                                ),
                              ),
                              Text(
                                '${_dateStr(e.eventDate)}${e.location != null && e.location!.isNotEmpty ? ' · ${e.location}' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: nav.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: e.status == 'approved'
                                ? Colors.green.withValues(alpha: 0.2)
                                : nav.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: nav,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: nav.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HoursAndLinksTab extends StatelessWidget {
  const _HoursAndLinksTab({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hours & links',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Edit business hours and social/website links. Same as owner view.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hours',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 16),
                BusinessHoursEditor(businessId: businessId),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social & links',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 16),
                BusinessLinksEditor(businessId: businessId),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// --- Subscription tab ---

class _SubscriptionTab extends StatefulWidget {
  const _SubscriptionTab({required this.businessId, required this.onUpdated});

  final String businessId;
  final VoidCallback onUpdated;

  @override
  State<_SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<_SubscriptionTab> {
  final BusinessSubscriptionsRepository _subRepo = BusinessSubscriptionsRepository();
  final BusinessPlansRepository _plansRepo = BusinessPlansRepository();
  BusinessSubscriptionWithPlan? _current;
  List<BusinessPlan> _plans = [];
  String? _selectedPlanId;
  final TextEditingController _trialDaysController = TextEditingController(text: '14');
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trialDaysController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _subRepo.getByBusinessId(widget.businessId),
      _plansRepo.list(),
    ]);
    final current = results[0] as BusinessSubscriptionWithPlan?;
    final plans = (results[1] as List<BusinessPlan>).where((p) => p.isActive).toList();
    if (mounted) {
      setState(() {
        _current = current;
        _plans = plans;
        _selectedPlanId = _selectedPlanId ?? (plans.isNotEmpty ? plans.first.id : null);
        _loading = false;
      });
    }
  }

  Future<void> _assignPlan({bool withTrial = false}) async {
    final planId = _selectedPlanId;
    if (planId == null) return;
    int? trialDays;
    if (withTrial) {
      trialDays = int.tryParse(_trialDaysController.text.trim());
      if (trialDays == null || trialDays < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid number of trial days (e.g. 7, 14, 30).')),
          );
        }
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _subRepo.assignPlanWithoutCheckout(widget.businessId, planId, trialDays: trialDays);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(withTrial ? 'Free trial started.' : 'Plan assigned.')),
        );
        widget.onUpdated();
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove subscription'),
        content: const Text(
          'This will remove the business\'s paid plan. They will have no active subscription.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _subRepo.removeSubscription(widget.businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription removed.')));
        widget.onUpdated();
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBusiness() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete business?'),
        content: const Text(
          'Permanently delete this business and all its data? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await BusinessRepository().deleteBusiness(widget.businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business deleted.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
    );

    if (_loading) {
      return const Center(child: AppLoader.page());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current subscription',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 12),
                if (_current == null)
                  Text(
                    'No plan — Free tier',
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        _current!.planName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.specNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _current!.planTier,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.specNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.specGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _current!.subscription.status,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.specNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_current!.subscription.status == 'trialing' &&
                      _current!.subscription.currentPeriodEnd != null)
                    Text(
                      'Trial ends ${_formatDate(_current!.subscription.currentPeriodEnd)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
                    )
                  else if (_current!.subscription.currentPeriodStart != null ||
                      _current!.subscription.currentPeriodEnd != null)
                    Text(
                      'Period: ${_formatDate(_current!.subscription.currentPeriodStart)} – ${_formatDate(_current!.subscription.currentPeriodEnd)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SpecCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign plan (no checkout)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Plan',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _plans.any((p) => p.id == _selectedPlanId) ? _selectedPlanId : null,
                  decoration: InputDecoration(
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                  dropdownColor: AppTheme.specWhite,
                  items: _plans
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.tier})', style: TextStyle(color: AppTheme.specNavy)),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() => _selectedPlanId = id),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        onPressed: _saving ? null : () => _assignPlan(withTrial: false),
                        icon: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specWhite),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: const Text('Assign plan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Free trial',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _trialDaysController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy),
                        decoration: InputDecoration(
                          labelText: 'Days',
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border.copyWith(
                            borderSide: BorderSide(color: AppTheme.specGold, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      onPressed: _saving ? null : () => _assignPlan(withTrial: true),
                      icon: const Icon(Icons.timer_outlined, size: 20),
                      label: const Text('Start free trial'),
                    ),
                  ],
                ),
                if (_current != null) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  AppOutlinedButton(
                    onPressed: _saving ? null : _removeSubscription,
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                    label: const Text('Remove subscription'),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  'Danger zone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.specRed,
                  ),
                ),
                const SizedBox(height: 8),
                AppDangerOutlinedButton(
                  onPressed: _saving ? null : _deleteBusiness,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Delete business'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
