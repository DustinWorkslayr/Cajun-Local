import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/pending_approval_screen.dart';
import 'package:cajun_local/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/controllers/create_listing_controller.dart';

/// User/business owner: create a single listing. Brand theme (specOffWhite, specNavy, specGold).
/// No CSV; that is admin-only on AdminAddBusinessScreen.
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    
    final success = await ref.read(createListingControllerProvider.notifier).submit(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
    );

    if (success && mounted) {
      final state = ref.read(createListingControllerProvider).value;
      if (state?.createdBusinessId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PendingApprovalScreen(
              businessId: state!.createdBusinessId!,
              businessName: _nameController.text.trim().isEmpty ? 'Your listing' : _nameController.text.trim(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    const cardRadius = 16.0;
    final asyncState = ref.watch(createListingControllerProvider);

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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
        error: (err, st) => Center(child: Text('Error loading form data: $err')),
        data: (state) => SingleChildScrollView(
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
                      decoration: BoxDecoration(color: AppTheme.specGold, borderRadius: BorderRadius.circular(2)),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                       DropdownButtonFormField<Parish>(
                        initialValue: state.selectedParish,
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
                        items: state.parishes.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                        onChanged: (p) => ref.read(createListingControllerProvider.notifier).updateParish(p),
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
                       DropdownButtonFormField<BusinessCategory>(
                        initialValue: state.selectedCategory,
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
                        items: state.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (c) => ref.read(createListingControllerProvider.notifier).updateCategory(c),
                        validator: (v) => v == null ? 'Please select a category' : null,
                      ),
                      if (state.selectedCategory != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Tags (optional)',
                          style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 8),
                        if (state.subcategoriesLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                          )
                        else if (state.subcategories.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.subcategories.map((s) {
                              final selected = state.selectedSubcategoryIds.contains(s.id);
                              return FilterChip(
                                label: Text(s.name),
                                selected: selected,
                                onSelected: (_) => ref.read(createListingControllerProvider.notifier).toggleSubcategory(s.id),
                                selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                                checkmarkColor: AppTheme.specNavy,
                                side: BorderSide(
                                  color: selected ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.3),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'No tags for this category.',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.6)),
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
                              value: state.agreedToPrivacy,
                              onChanged: (v) => ref.read(createListingControllerProvider.notifier).updateAgreedToPrivacy(v ?? false),
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
                      if (state.message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            state.message!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: state.success ? AppTheme.specNavy : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      AppSecondaryButton(
                        onPressed: state.submitting ? null : _submit,
                        icon: state.submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specWhite),
                              )
                            : const Icon(Icons.add_rounded, size: 22),
                        label: Text(state.submitting ? 'Creating…' : 'Create listing'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
