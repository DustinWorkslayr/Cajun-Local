import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/ad_package.dart';
import 'package:my_app/core/data/repositories/ad_packages_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: add or edit an ad package.
class AdminAdPackageFormScreen extends StatefulWidget {
  const AdminAdPackageFormScreen({super.key, this.package});

  final AdPackage? package;

  @override
  State<AdminAdPackageFormScreen> createState() =>
      _AdminAdPackageFormScreenState();
}

class _AdminAdPackageFormScreenState extends State<AdminAdPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationDaysController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxImpressionsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stripePriceIdController = TextEditingController();
  final _sortOrderController = TextEditingController();
  String _placement = 'homepage_featured';
  bool _isActive = true;
  bool _saving = false;
  String? _message;

  static const List<String> _placements = [
    'directory_top',
    'category_banner',
    'search_results',
    'deal_spotlight',
    'homepage_featured',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    if (p != null) {
      _nameController.text = p.name;
      _placement = p.placement;
      _durationDaysController.text = p.durationDays.toString();
      _priceController.text = p.price.toString();
      _maxImpressionsController.text = p.maxImpressions?.toString() ?? '';
      _descriptionController.text = p.description ?? '';
      _stripePriceIdController.text = p.stripePriceId ?? '';
      _sortOrderController.text = p.sortOrder.toString();
      _isActive = p.isActive;
    } else {
      _durationDaysController.text = '7';
      _sortOrderController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationDaysController.dispose();
    _priceController.dispose();
    _maxImpressionsController.dispose();
    _descriptionController.dispose();
    _stripePriceIdController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final repo = AdPackagesRepository();
      final duration =
          int.tryParse(_durationDaysController.text.trim()) ?? 7;
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
      final maxImp = _maxImpressionsController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxImpressionsController.text.trim());
      final stripeId = _stripePriceIdController.text.trim();
      final desc = _descriptionController.text.trim();

      if (widget.package != null) {
        final updated = AdPackage(
          id: widget.package!.id,
          name: _nameController.text.trim(),
          placement: _placement,
          durationDays: duration,
          price: price,
          maxImpressions: maxImp,
          description: desc.isEmpty ? null : desc,
          stripePriceId: stripeId.isEmpty ? null : stripeId,
          isActive: _isActive,
          sortOrder: sortOrder,
          createdAt: widget.package!.createdAt,
          updatedAt: widget.package!.updatedAt,
        );
        await repo.update(updated);
      } else {
        final created = AdPackage(
          id: '',
          name: _nameController.text.trim(),
          placement: _placement,
          durationDays: duration,
          price: price,
          maxImpressions: maxImp,
          description: desc.isEmpty ? null : desc,
          stripePriceId: stripeId.isEmpty ? null : stripeId,
          isActive: _isActive,
          sortOrder: sortOrder,
        );
        await repo.insert(created);
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);
    final isEdit = widget.package != null;

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
          isEdit ? 'Edit ad package' : 'Add ad package',
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Package name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. Homepage Spotlight - 7 Days',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Placement',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RadioGroup<String>(
                groupValue: _placement,
                onChanged: (v) {
                  if (v != null) setState(() => _placement = v);
                },
                child: Column(
                  children: _placements
                      .map((p) => RadioListTile<String>(
                            title: Text(
                              AdPackage.placementLabel(p),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.specNavy,
                              ),
                            ),
                            value: p,
                            fillColor: WidgetStateProperty.resolveWith(
                              (Set<WidgetState> states) =>
                                  states.contains(WidgetState.selected)
                                      ? AppTheme.specNavy
                                      : null,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationDaysController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (days)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxImpressionsController,
                decoration: const InputDecoration(
                  labelText: 'Max impressions (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'Leave empty for unlimited',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Stripe',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'One-time payment Price ID from Stripe Dashboard.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stripePriceIdController,
                decoration: const InputDecoration(
                  labelText: 'Stripe Price ID',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. price_1ABC...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  'Active',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.specNavy,
                  ),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppTheme.specNavy,
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specRed,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppSecondaryButton(
                onPressed: _saving ? null : _submit,
                expanded: true,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEdit ? 'Save changes' : 'Create package'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
