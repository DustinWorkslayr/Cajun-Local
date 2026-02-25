import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';

/// First-time onboarding: welcoming flow — pick parishes, what you hope for, optional support.
/// Caller saves parish IDs via UserParishPreferences and dismisses on completion.
class ParishOnboardingDialog extends StatefulWidget {
  const ParishOnboardingDialog({
    super.key,
    required this.onComplete,
    this.onSupportTap,
  });

  /// Called with selected parish IDs when user finishes the flow. Caller saves and dismisses.
  final void Function(Set<String> selectedParishIds) onComplete;

  /// Optional. When user taps "Start Free Trial" on the support step (e.g. open pay screen).
  final VoidCallback? onSupportTap;

  @override
  State<ParishOnboardingDialog> createState() => _ParishOnboardingDialogState();
}

class _ParishOnboardingDialogState extends State<ParishOnboardingDialog>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 3;
  int _step = 0;

  final Set<String> _selectedParishIds = {};
  final Set<String> _selectedInterests = {};
  List<MockParish> _parishes = [];
  bool _parishesLoaded = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parishesLoaded && _parishes.isEmpty) {
      _loadParishes();
    }
  }

  Future<void> _loadParishes() async {
    final ds = AppDataScope.of(context).dataSource;
    final list = await ds.getParishes();
    if (mounted) {
      setState(() {
        _parishes = list;
        _parishesLoaded = true;
      });
    }
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
    widget.onComplete(Set.from(_selectedParishIds));
  }

  void _onSupportThenFinish() {
    widget.onSupportTap?.call();
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
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Column(
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
                                ? _buildParishStep(theme)
                                : _step == 1
                                    ? _buildInterestsStep(theme)
                                    : _buildSupportStep(theme),
                          ),
                        ),
                      ),
                      _buildFooter(theme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isSupportStep = _step == 2;
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
              "We're glad you're here!",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.specGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_step == 0) const SizedBox(height: 8),
          const AppLogo(height: 64),
          const SizedBox(height: 12),
          Text(
            'Step ${_step + 1} of $_totalSteps',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          if (!isSupportStep) ...[
            const SizedBox(height: 12),
            Text(
              _step == 0
                  ? 'Pick the parishes to explore'
                  : 'What do you hope to get from the app?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _step == 0
                  ? "Choose one or more areas — we'll show you local businesses and events there. You can change this anytime in Filters."
                  : "Select what you're most excited about. We'll use this to tailor your experience.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParishStep(ThemeData theme) {
    if (!_parishesLoaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _parishes.map((p) {
          final selected = _selectedParishIds.contains(p.id);
          return FilterChip(
            label: Text(p.name),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _selectedParishIds.add(p.id);
                } else {
                  _selectedParishIds.remove(p.id);
                }
              });
            },
            selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
            checkmarkColor: AppTheme.specNavy,
            backgroundColor: AppTheme.specNavy.withValues(alpha: 0.06),
            side: BorderSide(
              color: selected ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Hopes / expectations (first-time users haven't used the app yet).
  static const List<({String id, String label})> _hopeOptions = [
    (id: 'eat', label: 'Find great places to eat'),
    (id: 'events', label: 'Discover events & live music'),
    (id: 'deals', label: 'Save with deals & punch cards'),
    (id: 'discover', label: 'Discover new spots'),
    (id: 'support_local', label: 'Support local businesses'),
    (id: 'all', label: 'A bit of everything'),
  ];

  Widget _buildInterestsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _hopeOptions.map((o) {
          final selected = _selectedInterests.contains(o.id);
          return FilterChip(
            label: Text(o.label),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _selectedInterests.add(o.id);
                } else {
                  _selectedInterests.remove(o.id);
                }
              });
            },
            selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
            checkmarkColor: AppTheme.specNavy,
            backgroundColor: AppTheme.specNavy.withValues(alpha: 0.06),
            side: BorderSide(
              color: selected ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          );
        }).toList(),
      ),
    );
  }

  static const String _price = '\$2.99';

  Widget _buildSupportStep(ThemeData theme) {
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final gray = nav.withValues(alpha: 0.6);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cajun+ Membership',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: nav,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Support Local. Stay Cajun.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: sub,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(color: sub, height: 1.4),
              children: [
                const TextSpan(text: 'Get full access for '),
                TextSpan(
                  text: '$_price/month',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _OnboardingFeatureRow(label: 'Submit / request new businesses'),
          const SizedBox(height: 10),
          _OnboardingFeatureRow(label: 'Save unlimited favorites'),
          const SizedBox(height: 10),
          _OnboardingFeatureRow(label: 'AI-powered business requests'),
          const SizedBox(height: 10),
          _OnboardingFeatureRow(label: 'Early access to new features'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.6)),
            ),
            child: Text(
              '$_price/mo • Cancel anytime',
              style: theme.textTheme.titleSmall?.copyWith(
                color: nav,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onSupportThenFinish,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.specGold,
                      AppTheme.specGold.withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.specGold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Start Free Trial',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: nav,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Secure payment via App Store / Google Play. Cancel anytime.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: gray,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 20);

    if (_step == 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: padding,
            child: TextButton(
              onPressed: _finish,
              child: Text(
                'Maybe later',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_step == 0) {
      final canContinue = _selectedParishIds.isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: padding,
            child: AppSecondaryButton(
              onPressed: canContinue ? _next : null,
              expanded: true,
              child: Text(canContinue ? 'Continue' : 'Select at least one parish'),
            ),
          ),
        ],
      );
    }

    // Step 1 (interests) — optional, can skip
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
}

class _OnboardingFeatureRow extends StatelessWidget {
  const _OnboardingFeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.specGold,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 16, color: nav),
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
