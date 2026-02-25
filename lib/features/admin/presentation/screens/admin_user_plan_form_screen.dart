import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: add or edit a user subscription plan.
class AdminUserPlanFormScreen extends StatefulWidget {
  const AdminUserPlanFormScreen({super.key, this.plan});

  final UserPlan? plan;

  @override
  State<AdminUserPlanFormScreen> createState() => _AdminUserPlanFormScreenState();
}

class _AdminUserPlanFormScreenState extends State<AdminUserPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceMonthlyController = TextEditingController();
  final _priceYearlyController = TextEditingController();
  final _stripePriceIdMonthlyController = TextEditingController();
  final _stripePriceIdYearlyController = TextEditingController();
  final _stripeProductIdController = TextEditingController();
  final _sortOrderController = TextEditingController();
  String _tier = 'free';
  bool _exclusiveDeals = false;
  bool _isActive = true;
  bool _saving = false;
  String? _message;
  bool _success = false;

  static const List<String> _tiers = ['free', 'plus', 'pro'];

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
      _sortOrderController.text = p.sortOrder.toString();
      _isActive = p.isActive;
      _exclusiveDeals = p.features['exclusive_deals'] == true;
    } else {
      _sortOrderController.text = '0';
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
    _sortOrderController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFeatures() {
    final map = <String, dynamic>{};
    if (_exclusiveDeals) {
      map['exclusive_deals'] = true;
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
      final repo = UserPlansRepository();
      final monthly = double.tryParse(_priceMonthlyController.text.trim()) ?? 0;
      final yearly = double.tryParse(_priceYearlyController.text.trim()) ?? 0;
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

      final stripeMonthly = _stripePriceIdMonthlyController.text.trim();
      final stripeYearly = _stripePriceIdYearlyController.text.trim();
      final stripeProduct = _stripeProductIdController.text.trim();
      if (widget.plan != null) {
        final updated = UserPlan(
          id: widget.plan!.id,
          name: _nameController.text.trim(),
          tier: _tier,
          priceMonthly: monthly,
          priceYearly: yearly,
          features: features,
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
        final created = UserPlan(
          id: '',
          name: _nameController.text.trim(),
          tier: _tier,
          priceMonthly: monthly,
          priceYearly: yearly,
          features: features,
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
          _message =
              widget.plan != null ? 'Plan updated.' : 'Plan created.';
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
          isEdit ? 'Edit user plan' : 'Add user plan',
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
                  hintText: 'e.g. Plus',
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
                      .map<Widget>(
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
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Exclusive deals',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.specNavy,
                  ),
                ),
                subtitle: const Text(
                  'Allow access to exclusive local deals',
                ),
                value: _exclusiveDeals,
                onChanged: (v) => setState(() => _exclusiveDeals = v),
                activeThumbColor: AppTheme.specNavy,
              ),
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
