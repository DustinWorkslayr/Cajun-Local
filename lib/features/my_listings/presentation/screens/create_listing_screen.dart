import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/my_listings/presentation/screens/pending_approval_screen.dart';
import 'package:my_app/features/profile/presentation/screens/privacy_policy_screen.dart';

const String _kStateLouisiana = 'LA';

/// User/business owner: create a single listing. Brand theme (specOffWhite, specNavy, specGold).
/// No CSV; that is admin-only on AdminAddBusinessScreen.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  MockParish? _selectedParish;
  List<MockParish> _parishes = [];
  List<BusinessCategory> _categories = [];
  List<Subcategory> _subcategories = [];
  BusinessCategory? _selectedCategory;
  final Set<String> _selectedSubcategoryIds = {};
  bool _categoriesLoading = true;
  bool _parishesLoading = true;
  bool _subcategoriesLoading = false;

  bool _agreedToPrivacy = false;
  String? _message;
  bool _success = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadParishes();
  }

  Future<void> _loadParishes() async {
    try {
      final ds = AppDataScope.of(context).dataSource;
      final list = await ds.getParishes();
      if (mounted) {
        setState(() {
          _parishes = list;
          _parishesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _parishes = [];
          _parishesLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await CategoryRepository().listCategories();
      if (mounted) {
        setState(() {
          _categories = list;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [];
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _onCategoryChanged(BusinessCategory? category) async {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategoryIds.clear();
      _subcategories = [];
      _subcategoriesLoading = category != null;
    });
    if (category == null) return;
    try {
      final list = await CategoryRepository().listSubcategories(categoryId: category.id);
      if (mounted) {
        setState(() {
          _subcategories = list;
          _subcategoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _subcategories = [];
          _subcategoriesLoading = false;
        });
      }
    }
  }

  void _toggleSubcategory(String id) {
    setState(() {
      if (_selectedSubcategoryIds.contains(id)) {
        _selectedSubcategoryIds.remove(id);
      } else {
        _selectedSubcategoryIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() {
        _message = 'Please select a category.';
        _success = false;
      });
      return;
    }
    if (_selectedParish == null) {
      setState(() {
        _message = 'Please select a parish.';
        _success = false;
      });
      return;
    }
    if (!_agreedToPrivacy) {
      setState(() {
        _message = 'Please agree to the Privacy Policy.';
        _success = false;
      });
      return;
    }
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) {
      setState(() {
        _message = 'You must be signed in.';
        _success = false;
      });
      return;
    }
    setState(() {
      _message = null;
      _loading = true;
    });
    try {
      final businessRepo = BusinessRepository();
      final businessId = await businessRepo.insertBusiness(
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        createdBy: uid,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _addressController.text.trim().isEmpty ? _selectedParish?.name : null,
        parish: _selectedParish?.id,
        state: _kStateLouisiana,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      );
      await businessRepo.setBusinessSubcategories(businessId, _selectedSubcategoryIds.toList());
      if (!mounted) return;
      setState(() {
        _message = 'Listing created.';
        _success = true;
        _loading = false;
      });
      final businessName = _nameController.text.trim();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PendingApprovalScreen(
            businessId: businessId,
            businessName: businessName.isEmpty ? 'Your listing' : businessName,
          ),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _message = e.toString();
        _success = false;
        _loading = false;
      });
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    const cardRadius = 16.0;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Create listing',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: padding.left, right: padding.right),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your business',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.specNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "We're local-first: your listing helps neighbors find you. All listings are in Louisiana and subject to approval before appearing in the directory. By creating a listing you agree to our Privacy Policy.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 4,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.specGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: EdgeInsets.symmetric(horizontal: padding.left),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Business name',
                        hintText: 'e.g. Acme Cafe',
                        filled: true,
                        fillColor: AppTheme.specOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                        ),
                        labelStyle: TextStyle(color: AppTheme.specNavy),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        filled: true,
                        fillColor: AppTheme.specOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                        ),
                        labelStyle: TextStyle(color: AppTheme.specNavy),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _parishesLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                          )
                        : DropdownButtonFormField<MockParish>(
                            initialValue: _selectedParish,
                            decoration: InputDecoration(
                              labelText: 'Parish',
                              filled: true,
                              fillColor: AppTheme.specOffWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                              ),
                              labelStyle: TextStyle(color: AppTheme.specNavy),
                            ),
                            hint: const Text('Select parish'),
                            items: _parishes
                                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                                .toList(),
                            onChanged: (p) => setState(() => _selectedParish = p),
                            validator: (v) => v == null ? 'Please select a parish' : null,
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        filled: true,
                        fillColor: AppTheme.specOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                        ),
                        labelStyle: TextStyle(color: AppTheme.specNavy),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: InputDecoration(
                        labelText: 'Website',
                        filled: true,
                        fillColor: AppTheme.specOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                        ),
                        labelStyle: TextStyle(color: AppTheme.specNavy),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    if (_categoriesLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                      )
                    else
                      DropdownButtonFormField<BusinessCategory>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: AppTheme.specOffWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                          ),
                          labelStyle: TextStyle(color: AppTheme.specNavy),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: _onCategoryChanged,
                        validator: (v) => v == null ? 'Please select a category' : null,
                      ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tags (optional)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_subcategoriesLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                        )
                      else if (_subcategories.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _subcategories.map((s) {
                            final selected = _selectedSubcategoryIds.contains(s.id);
                            return FilterChip(
                              label: Text(s.name),
                              selected: selected,
                              onSelected: (_) => _toggleSubcategory(s.id),
                              selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                              checkmarkColor: AppTheme.specNavy,
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.specGold
                                    : AppTheme.specNavy.withValues(alpha: 0.3),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No tags for this category.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToPrivacy,
                            onChanged: (v) => setState(() => _agreedToPrivacy = v ?? false),
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) return AppTheme.specNavy;
                              return AppTheme.specNavy.withValues(alpha: 0.3);
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.9),
                                  height: 1.35,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.specGold,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppTheme.specGold,
                                    ),
                                  ),
                                  const TextSpan(text: ' before creating my listing.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _success ? AppTheme.specNavy : theme.colorScheme.error,
                          ),
                        ),
                      ),
                    AppSecondaryButton(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specWhite),
                            )
                          : const Icon(Icons.add_rounded, size: 22),
                      label: Text(_loading ? 'Creating…' : 'Create listing'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
