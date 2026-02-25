import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';

/// First-time business owner onboarding: welcome + plan upsell (Free, \$9.99, \$29.99).
/// Caller marks completed via onComplete and can start checkout via onSelectPlan.
class OwnerOnboardingDialog extends StatefulWidget {
  const OwnerOnboardingDialog({
    super.key,
    required this.onComplete,
    this.onSelectPlan,
  });

  /// Called when user finishes (with or without selecting a paid plan). Caller should mark onboarding done and pop.
  final void Function() onComplete;

  /// When user selects a paid plan tier ('basic' = \$9.99, 'premium' = \$29.99). Caller can start Stripe/billing then call onComplete.
  final void Function(String tier)? onSelectPlan;

  /// Shows the onboarding dialog. When dismissed, [onComplete] is called (caller should mark onboarding done).
  static Future<void> show(
    BuildContext context, {
    required void Function() onComplete,
    void Function(String tier)? onSelectPlan,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => OwnerOnboardingDialog(
        onComplete: () {
          Navigator.of(ctx).pop();
          onComplete();
        },
        onSelectPlan: onSelectPlan,
      ),
    );
  }

  @override
  State<OwnerOnboardingDialog> createState() => _OwnerOnboardingDialogState();
}

class _OwnerOnboardingDialogState extends State<OwnerOnboardingDialog>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 2;
  int _step = 0;

  /// Selected plan: 'free', 'basic', 'premium'. Null = none chosen yet.
  String? _selectedPlan;

  late AnimationController _entranceController;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _entranceScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    widget.onComplete();
  }

  void _onSelectPlan(String tier) {
    setState(() => _selectedPlan = tier);
  }

  void _confirmPlan() {
    if (_selectedPlan == null || _selectedPlan == 'free') {
      _finish();
      return;
    }
    widget.onSelectPlan?.call(_selectedPlan!);
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Opacity(
            opacity: _entranceOpacity.value,
            child: Transform.scale(
              scale: _entranceScale.value,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: Material(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.specWhite,
          elevation: 24,
          shadowColor: AppTheme.specNavy.withValues(alpha: 0.25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(theme),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.15, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_step),
                        child: _step == 0
                            ? _buildWelcomeStep(theme)
                            : _buildPlanStep(theme),
                      ),
                    ),
                  ),
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          if (_step == 0)
            Text(
              "You're a business owner!",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.specGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_step == 0) const SizedBox(height: 8),
          if (_step == 0)
            const AppLogo(height: 56)
          else
            Image.asset(
              'assets/images/local+.png',
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const AppLogo(height: 56),
            ),
          const SizedBox(height: 12),
          Text(
            'Step ${_step + 1} of $_totalSteps',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _step == 0
                ? 'Welcome to your listing dashboard'
                : 'Choose your plan',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.specNavy,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _step == 0
                ? 'Update your details, add photos, manage deals and events — all in one place.'
                : 'Start free or unlock more visibility and features for your business.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OwnerFeatureRow(label: 'Edit your business details and hours'),
          const SizedBox(height: 10),
          _OwnerFeatureRow(label: 'Add photos and a cover image'),
          const SizedBox(height: 10),
          _OwnerFeatureRow(label: 'Create deals and punch cards'),
          const SizedBox(height: 10),
          _OwnerFeatureRow(label: 'Post events and specials'),
          const SizedBox(height: 10),
          _OwnerFeatureRow(label: 'Get found by locals in the directory'),
        ],
      ),
    );
  }

  static const List<({String id, String name, String price, String? sub})> _plans = [
    (id: 'free', name: 'Free', price: '\$0', sub: 'Get started — basic listing'),
    (id: 'basic', name: 'Basic', price: '\$9.99', sub: 'Per month — more visibility'),
    (id: 'premium', name: 'Premium', price: '\$29.99', sub: 'Per month — top placement & extras'),
  ];

  Widget _buildPlanStep(ThemeData theme) {
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: _plans.map((plan) {
          final selected = _selectedPlan == plan.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onSelectPlan(plan.id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.specGold.withValues(alpha: 0.2)
                        : AppTheme.specNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.specGold
                          : AppTheme.specNavy.withValues(alpha: 0.2),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 24,
                        color: selected ? AppTheme.specGold : sub,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: nav,
                              ),
                            ),
                            if (plan.sub != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                plan.sub!,
                                style: theme.textTheme.bodySmall?.copyWith(color: sub),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        plan.price,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: plan.id == 'free' ? sub : AppTheme.specGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 20);

    if (_step == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: padding,
            child: AppSecondaryButton(
              onPressed: _next,
              expanded: true,
              child: const Text('Continue'),
            ),
          ),
        ],
      );
    }

    // Plan step: Get started (with selection) or Maybe later
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: padding,
          child: Column(
            children: [
              AppPrimaryButton(
                onPressed: _confirmPlan,
                expanded: true,
                child: Text(
                  _selectedPlan == null || _selectedPlan == 'free'
                      ? 'Get started with Free'
                      : 'Continue with ${_selectedPlan == 'basic' ? 'Basic' : 'Premium'}',
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _finish,
                child: Text(
                  'Maybe later',
                  style: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerFeatureRow extends StatelessWidget {
  const _OwnerFeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppTheme.specGold,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 14, color: nav),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: nav.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
