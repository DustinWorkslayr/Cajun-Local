import 'package:flutter/material.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced "Unified Dialog" for parish and interest selection.
/// Matches the high-end editorial design from Stitch v2.
class ParishOnboardingDialog extends ConsumerStatefulWidget {
  const ParishOnboardingDialog({
    super.key,
    required this.onComplete,
    this.initialParishIds,
    this.initialInterestIds,
    this.parishOnly = false,
  });

  final void Function(Set<String> selectedParishIds, Set<String> selectedInterestIds) onComplete;
  final Set<String>? initialParishIds;
  final Set<String>? initialInterestIds;
  final bool parishOnly;

  @override
  ConsumerState<ParishOnboardingDialog> createState() => _ParishOnboardingDialogState();
}

class _ParishOnboardingDialogState extends ConsumerState<ParishOnboardingDialog> with SingleTickerProviderStateMixin {
  int _step = 0;
  late Set<String> _selectedParishIds;
  late Set<String> _selectedInterests;
  List<Parish> _parishes = [];
  bool _parishesLoaded = false;

  late AnimationController _entranceController;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;

  int get _totalSteps => widget.parishOnly ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _selectedParishIds = Set.from(widget.initialParishIds ?? []);
    _selectedInterests = Set.from(widget.initialInterestIds ?? []);
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _entranceScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
    );
    _entranceController.forward();
    _loadParishes();
  }

  Future<void> _loadParishes() async {
    final list = await ref.read(parishRepositoryProvider).listParishes();
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
    widget.onComplete(Set.from(_selectedParishIds), Set.from(_selectedInterests));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) => Opacity(
          opacity: _entranceOpacity.value,
          child: Transform.scale(scale: _entranceScale.value, child: child),
        ),
        child: Material(
          borderRadius: BorderRadius.circular(28),
          color: AppTheme.specWhite,
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          shadowColor: AppTheme.specNavy.withValues(alpha: 0.15),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _parishesLoaded
                        ? (_step == 0 ? _buildParishStep(theme) : _buildInterestsStep(theme))
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AppTheme.specGold),
                            ),
                          ),
                  ),
                ),
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_step + 1} OF $_totalSteps'.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.specGold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: List.generate(_totalSteps, (index) {
                  final active = index <= _step;
                  return Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.specGold : AppTheme.specSurfaceContainer,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _step == 0 ? 'Pick the parishes to explore' : 'Tell us your interests',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.specNavy,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _step == 0
                ? "Choose one or more local areas to discover matching businesses and cultural events."
                : "Select what you're most excited about so we can tailor your Acadiana experience.",
            style: GoogleFonts.libreBaskerville(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.specOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParishStep(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _parishes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _parishes[index];
        final isSelected = _selectedParishIds.contains(p.id);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedParishIds.remove(p.id);
              } else {
                _selectedParishIds.add(p.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.specGold.withValues(alpha: 0.05) : AppTheme.specSurfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.specGold : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.specGold.withValues(alpha: 0.1) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected ? AppTheme.specGold : AppTheme.specOutline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    p.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? AppTheme.specNavy : AppTheme.specOnSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v ?? false) {
                        _selectedParishIds.add(p.id);
                      } else {
                        _selectedParishIds.remove(p.id);
                      }
                    });
                  },
                  activeColor: AppTheme.specGold,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: AppTheme.specOutline.withValues(alpha: 0.4), width: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterestsStep(ThemeData theme) {
    const options = [
      (id: 'eat', label: 'Find great places to eat', icon: Icons.restaurant_menu_rounded),
      (id: 'events', label: 'Discover events & live music', icon: Icons.straighten_rounded),
      (id: 'deals', label: 'Save with deals & punch cards', icon: Icons.local_offer_rounded),
      (id: 'discover', label: 'Discover new spots', icon: Icons.explore_rounded),
      (id: 'support_local', label: 'Support local businesses', icon: Icons.volunteer_activism_rounded),
      (id: 'all', label: 'A bit of everything', icon: Icons.auto_awesome_rounded),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final o = options[index];
        final isSelected = _selectedInterests.contains(o.id);
        void toggle() {
          setState(() {
            if (isSelected) {
              _selectedInterests.remove(o.id);
            } else {
              if (o.id == 'all') {
                _selectedInterests.clear();
                _selectedInterests.add('all');
              } else {
                _selectedInterests.remove('all');
                _selectedInterests.add(o.id);
              }
            }
          });
        }

        return InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.specNavy.withValues(alpha: 0.05) : AppTheme.specSurfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.specNavy : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  o.icon,
                  size: 20,
                  color: isSelected ? AppTheme.specNavy : AppTheme.specOutline,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    o.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? AppTheme.specNavy : AppTheme.specOnSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => toggle(),
                  activeColor: AppTheme.specGold,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: AppTheme.specOutline.withValues(alpha: 0.4), width: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final canContinue = _selectedParishIds.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canContinue ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.specNavy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.specNavy.withValues(alpha: 0.12),
                disabledForegroundColor: AppTheme.specNavy.withValues(alpha: 0.38),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _step == 0 && !widget.parishOnly ? 'Continue' : 'Get Started',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Skip for now',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.specOutline,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
