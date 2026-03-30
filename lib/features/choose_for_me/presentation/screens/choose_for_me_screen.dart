import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/categories/data/models/subcategory.dart';
import 'package:cajun_local/features/locations/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/features/choose_for_me/presentation/screens/choose_for_me_slot_screen.dart'
    show showChooseForMeSlotDialog;

/// "Choose for me" flow: step 1 = preferred parish + category + optional tags (subcategories);
/// step 2 = popup with slot-machine style randomizer using Explore-style listing cards.
class ChooseForMeScreen extends ConsumerStatefulWidget {
  const ChooseForMeScreen({super.key});

  @override
  ConsumerState<ChooseForMeScreen> createState() => _ChooseForMeScreenState();
}

class _ChooseForMeScreenState extends ConsumerState<ChooseForMeScreen> with TickerProviderStateMixin {
  Set<String> _parishIds = {};
  List<Parish> _parishes = [];

  /// Single category selection (one category only).
  String? _selectedCategoryId;
  Set<String> _subcategoryIds = {};
  bool _parishesLoaded = false;

  /// True once listCategories() has completed (success or failure).
  bool _categoriesLoaded = false;

  /// All categories (any bucket) for dynamic category select.
  List<BusinessCategory> _allCategories = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPreferredParishes();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredParishes() async {
    try {
      final ids = await UserParishPreferences.getPreferredParishIds();
      final list = await ref.read(parishRepositoryProvider).listParishes();
      if (!mounted) return;
      setState(() {
        _parishIds = Set.from(ids);
        _parishes = list;
        _parishesLoaded = true;
      });
    } catch (_) {
      final ids = await UserParishPreferences.getPreferredParishIds();
      if (!mounted) return;
      setState(() {
        _parishIds = Set.from(ids);
        _parishes = [];
        _parishesLoaded = true;
      });
    }
  }

  /// Load all categories for dynamic category + tags (subcategory) select.
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _categoriesLoaded = false;
    });
    try {
      final categories = await ref.read(categoryRepositoryProvider).listCategories();
      if (!mounted) return;
      setState(() {
        _allCategories = categories;
        _categoriesLoaded = true;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ChooseForMe _loadCategories failed: $e');
        debugPrintStack(stackTrace: st);
      }
      if (mounted) {
        setState(() {
          _allCategories = [];
          _categoriesLoaded = true;
        });
      }
    }
  }

  /// Subcategories (tags) from the selected category only.
  List<Subcategory> get _selectedSubcategories {
    if (_selectedCategoryId == null) return [];
    for (final c in _allCategories) {
      if (c.id == _selectedCategoryId) return c.subcategories;
    }
    return [];
  }

  void _goToSlot() {
    if (_parishIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one preferred area.')));
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category.')));
      return;
    }
    final parishIds = _parishIds;
    final categoryId = _selectedCategoryId!;
    final subcategoryIds = _subcategoryIds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UserParishPreferences.setPreferredParishIds(parishIds);
      showChooseForMeSlotDialog(
        context: context,
        parishIds: parishIds,
        categoryIds: {categoryId},
        subcategoryIds: subcategoryIds,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;

    final pulseScale = 1.0 + 0.04 * Curves.easeInOut.transform(_pulseController.value);
    final canGo = _parishIds.isNotEmpty && _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: const AppBarWidget(title: 'CHOOSE FOR ME', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedEntrance(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indecisive?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: nav,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Libre Baskerville',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick your vibe and let our slot machine decide where your next adventure begins.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: nav.withValues(alpha: 0.6), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 1. Area Selection
              _buildSectionHeader(context, '1. WHERE ARE YOU?', Icons.location_on_rounded),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 200),
                child: _parishesLoaded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _parishes.map((p) {
                            final selected = _parishIds.contains(p.id);
                            return FilterChip(
                              label: Text(p.name),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _parishIds = Set.from(_parishIds)..add(p.id);
                                  } else {
                                    _parishIds = Set.from(_parishIds)..remove(p.id);
                                  }
                                });
                                UserParishPreferences.setPreferredParishIds(_parishIds);
                              },
                              backgroundColor: AppTheme.specWhite,
                              selectedColor: AppTheme.specGold.withValues(alpha: 0.15),
                              checkmarkColor: AppTheme.specGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: selected ? AppTheme.specGold : nav.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                              ),
                              labelStyle: theme.textTheme.labelLarge?.copyWith(
                                color: selected ? AppTheme.specNavy : nav.withValues(alpha: 0.6),
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: LinearProgressIndicator(color: AppTheme.specGold, backgroundColor: Colors.white),
                      ),
              ),

              const SizedBox(height: 32),

              /// 2. Category Selection
              _buildSectionHeader(context, '2. WHAT ARE YOU LOOKING FOR?', Icons.grid_view_rounded),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 300),
                child: _categoriesLoaded
                    ? _buildCategoryList()
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specGold)),
                      ),
              ),

              const SizedBox(height: 32),

              /// 3. Subcategories (Action/Tags)
              if (_selectedSubcategories.isNotEmpty) ...[
                _buildSectionHeader(context, '3. ADD SOME FLAVOR', Icons.label_rounded),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSubcategories.map((s) {
                        final selected = _subcategoryIds.contains(s.id);
                        return FilterChip(
                          label: Text(s.name),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _subcategoryIds = Set.from(_subcategoryIds)..add(s.id);
                            } else {
                              _subcategoryIds = Set.from(_subcategoryIds)..remove(s.id);
                            }
                          }),
                          backgroundColor: AppTheme.specWhite.withValues(alpha: 0.5),
                          selectedColor: AppTheme.specNavy.withValues(alpha: 0.1),
                          shape: StadiumBorder(
                            side: BorderSide(color: selected ? AppTheme.specNavy : nav.withValues(alpha: 0.1)),
                          ),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: selected ? AppTheme.specNavy : nav.withValues(alpha: 0.6),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],

              /// Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 64),
                child: AppPrimaryButton(
                  onPressed: !canGo ? null : _goToSlot,
                  label: Text('SPIN'),
                  icon: Icon(Icons.casino_rounded, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.specGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.6),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _allCategories.length,
        itemBuilder: (context, index) {
          final cat = _allCategories[index];
          final isSelected = _selectedCategoryId == cat.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _selectedCategoryId = isSelected ? null : cat.id;
                  _subcategoryIds = {};
                }),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.specGold : AppTheme.specWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.specGold : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.specGold.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(cat.name),
                        size: 32,
                        color: isSelected ? AppTheme.specOffWhite : AppTheme.specNavy.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat.name.split(' ').first, // Keep it short
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppTheme.specOffWhite : AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('restauran') || n.contains('dining') || n.contains('food')) return Icons.restaurant_rounded;
    if (n.contains('shop') || n.contains('retail')) return Icons.shopping_bag_rounded;
    if (n.contains('event') || n.contains('happening')) return Icons.event_rounded;
    if (n.contains('lifestyle') || n.contains('beauty')) return Icons.auto_awesome_rounded;
    if (n.contains('service')) return Icons.support_agent_rounded;
    if (n.contains('professional')) return Icons.business_center_rounded;
    if (n.contains('local tips')) return Icons.lightbulb_rounded;
    return Icons.grid_view_rounded;
  }
}
