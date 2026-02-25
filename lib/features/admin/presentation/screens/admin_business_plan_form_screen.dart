import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business_plan.dart';
import 'package:my_app/core/data/repositories/business_plans_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: add or edit a business subscription plan.
class AdminBusinessPlanFormScreen extends StatefulWidget {
  const AdminBusinessPlanFormScreen({super.key, this.plan});

  final BusinessPlan? plan;

  @override
  State<AdminBusinessPlanFormScreen> createState() =>
      _AdminBusinessPlanFormScreenState();
}

class _AdminBusinessPlanFormScreenState
    extends State<AdminBusinessPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceMonthlyController = TextEditingController();
  final _priceYearlyController = TextEditingController();
  final _stripePriceIdMonthlyController = TextEditingController();
  final _stripePriceIdYearlyController = TextEditingController();
  final _stripeProductIdController = TextEditingController();
  final _maxLocationsController = TextEditingController();
  final _sortOrderController = TextEditingController();
  final _maxDealsController = TextEditingController();
  final _maxImagesController = TextEditingController();
  String _tier = 'free';
  bool _isActive = true;
  bool _saving = false;
  String? _message;
  bool _success = false;

  static const List<String> _tiers = ['free', 'basic', 'premium', 'enterprise'];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _nameController.text = p.name;
      _tier = p.tier;
      _priceMonthlyController.text = p.priceMonthly.toString();
      _priceYearlyController.text = p.priceYearly.toString();
      _stripePriceIdMonthlyController.text = p.stripePriceIdMonthly ?? '';
      _stripePriceIdYearlyController.text = p.stripePriceIdYearly ?? '';
      _stripeProductIdController.text = p.stripeProductId ?? '';
      _maxLocationsController.text = p.maxLocations.toString();
      _sortOrderController.text = p.sortOrder.toString();
      _isActive = p.isActive;
      _maxDealsController.text = (p.features['max_deals'] is num)
          ? (p.features['max_deals'] as num).toInt().toString()
          : (p.features['max_deals']?.toString() ?? '');
      _maxImagesController.text = (p.features['max_images'] is num)
          ? (p.features['max_images'] as num).toInt().toString()
          : (p.features['max_images']?.toString() ?? '');
    } else {
      _maxLocationsController.text = '1';
      _sortOrderController.text = '0';
      _maxDealsController.text = '';
      _maxImagesController.text = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceMonthlyController.dispose();
    _priceYearlyController.dispose();
    _stripePriceIdMonthlyController.dispose();
    _stripePriceIdYearlyController.dispose();
    _stripeProductIdController.dispose();
    _maxLocationsController.dispose();
    _sortOrderController.dispose();
    _maxDealsController.dispose();
    _maxImagesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFeatures() {
    final map = <String, dynamic>{};
    final maxDeals = int.tryParse(_maxDealsController.text.trim());
    if (maxDeals != null && maxDeals > 0) {
      map['max_deals'] = maxDeals;
    }
    final maxImages = int.tryParse(_maxImagesController.text.trim());
    if (maxImages != null && maxImages > 0) {
      map['max_images'] = maxImages;
    }
    return map;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final features = _buildFeatures();
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      final repo = BusinessPlansRepository();
      final monthly = double.tryParse(_priceMonthlyController.text.trim()) ?? 0;
      final yearly = double.tryParse(_priceYearlyController.text.trim()) ?? 0;
      final maxLoc =
          int.tryParse(_maxLocationsController.text.trim()) ?? 1;
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

      final stripeMonthly = _stripePriceIdMonthlyController.text.trim();
      final stripeYearly = _stripePriceIdYearlyController.text.trim();
      final stripeProduct = _stripeProductIdController.text.trim();
      if (widget.plan != null) {
        final updated = BusinessPlan(
          id: widget.plan!.id,
          name: _nameController.text.trim(),
          tier: _tier,
          priceMonthly: monthly,
          priceYearly: yearly,
          features: features,
          maxLocations: maxLoc < 1 ? 1 : maxLoc,
          stripePriceIdMonthly: stripeMonthly.isEmpty ? null : stripeMonthly,
          stripePriceIdYearly: stripeYearly.isEmpty ? null : stripeYearly,
          stripeProductId: stripeProduct.isEmpty ? null : stripeProduct,
          isActive: _isActive,
          sortOrder: sortOrder,
          createdAt: widget.plan!.createdAt,
          updatedAt: widget.plan!.updatedAt,
        );
        await repo.update(updated);
      } else {
        final created = BusinessPlan(
          id: '',
          name: _nameController.text.trim(),
          tier: _tier,
          priceMonthly: monthly,
          priceYearly: yearly,
          features: features,
          maxLocations: maxLoc < 1 ? 1 : maxLoc,
          stripePriceIdMonthly: stripeMonthly.isEmpty ? null : stripeMonthly,
          stripePriceIdYearly: stripeYearly.isEmpty ? null : stripeYearly,
          stripeProductId: stripeProduct.isEmpty ? null : stripeProduct,
          isActive: _isActive,
          sortOrder: sortOrder,
        );
        await repo.insert(created);
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = widget.plan != null ? 'Plan updated.' : 'Plan created.';
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
    final isEdit = widget.plan != null;

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
          isEdit ? 'Edit business plan' : 'Add business plan',
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
                  labelText: 'Plan name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. Basic',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Tier',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RadioGroup<String>(
                groupValue: _tier,
                onChanged: (v) {
                  if (v != null) setState(() => _tier = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _tiers
                      .map(
                        (t) => RadioListTile<String>(
                          title: Text(
                            t.substring(0, 1).toUpperCase() + t.substring(1),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.specNavy,
                            ),
                          ),
                          value: t,
                          fillColor: WidgetStateProperty.resolveWith(
                            (Set<WidgetState> states) =>
                                states.contains(WidgetState.selected)
                                    ? AppTheme.specNavy
                                    : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Stripe (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From Stripe Dashboard → Products → your product → copy Price ID and Product ID.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stripePriceIdMonthlyController,
                decoration: const InputDecoration(
                  labelText: 'Stripe Price ID (monthly)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. price_1ABC...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stripePriceIdYearlyController,
                decoration: const InputDecoration(
                  labelText: 'Stripe Price ID (yearly)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. price_1DEF...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stripeProductIdController,
                decoration: const InputDecoration(
                  labelText: 'Stripe Product ID',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: 'e.g. prod_...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceMonthlyController,
                      decoration: const InputDecoration(
                        labelText: 'Price (monthly \$)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceYearlyController,
                      decoration: const InputDecoration(
                        labelText: 'Price (yearly \$)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxLocationsController,
                decoration: const InputDecoration(
                  labelText: 'Max locations',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: '1',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'At least 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.specWhite,
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Text(
                'Features',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.specNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxDealsController,
                      decoration: const InputDecoration(
                        labelText: 'Max deals',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                        hintText: 'e.g. 5',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Non-negative number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxImagesController,
                      decoration: const InputDecoration(
                        labelText: 'Max images',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                        hintText: 'e.g. 20',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Non-negative number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Active',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.specNavy,
                  ),
                ),
                subtitle: const Text('Inactive plans are hidden from selection'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppTheme.specNavy,
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
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save changes' : 'Create plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
