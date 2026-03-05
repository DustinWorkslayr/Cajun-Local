import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/app_logo.dart';

/// First-time onboarding or parish selector: pick parishes; optionally a second step for interests.
/// Caller saves parish IDs via UserParishPreferences and dismisses on completion.
/// Use [initialParishIds] when re-opening to change parishes (e.g. from home chip).
/// Use [parishOnly: true] to show only the parish step with a "Done" button.
class ParishOnboardingDialog extends StatefulWidget {
  const ParishOnboardingDialog({
    super.key,
    required this.onComplete,
    this.initialParishIds,
    this.parishOnly = false,
  });

  /// Called with selected parish IDs when user finishes the flow. Caller saves and dismisses.
  final void Function(Set<String> selectedParishIds) onComplete;

  /// Pre-select these parish IDs (e.g. current preferences when re-opening to change parishes).
  final Set<String>? initialParishIds;

  /// If true, only show the parish step; footer shows "Done" and completes immediately.
  final bool parishOnly;

  @override
  State<ParishOnboardingDialog> createState() => _ParishOnboardingDialogState();
}

class _ParishOnboardingDialogState extends State<ParishOnboardingDialog>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  late Set<String> _selectedParishIds;
  final Set<String> _selectedInterests = {};
  List<MockParish> _parishes = [];
  bool _parishesLoaded = false;

  late AnimationController _entranceController;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;

  int get _totalSteps => widget.parishOnly ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _selectedParishIds = Set.from(widget.initialParishIds ?? []);
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
                                : _buildInterestsStep(theme),
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

  Widget _buildFooter(ThemeData theme) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 20);

    if (_step == 0) {
      final canContinue = _selectedParishIds.isNotEmpty;
      final isDone = widget.parishOnly;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: padding,
            child: AppSecondaryButton(
              onPressed: canContinue ? (isDone ? _finish : _next) : null,
              expanded: true,
              child: Text(
                canContinue
                    ? (isDone ? 'Done' : 'Continue')
                    : 'Select at least one parish',
              ),
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
