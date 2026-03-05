import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/choose_for_me/presentation/screens/choose_for_me_slot_screen.dart' show showChooseForMeSlotDialog;

/// Asset for the Choose for me hero illustration (selection screen).
const String _kChooseForMeAsset = 'assets/images/chooseforme.png';

/// "Choose for me" flow: step 1 = preferred parish + category + optional tags (subcategories);
/// step 2 = popup with slot-machine style randomizer using Explore-style listing cards.
class ChooseForMeScreen extends StatefulWidget {
  const ChooseForMeScreen({super.key});

  @override
  State<ChooseForMeScreen> createState() => _ChooseForMeScreenState();
}

class _ChooseForMeScreenState extends State<ChooseForMeScreen> with TickerProviderStateMixin {
  Set<String> _parishIds = {};
  List<MockParish> _parishes = [];
  /// Single category selection (one category only).
  String? _selectedCategoryId;
  Set<String> _subcategoryIds = {};
  bool _parishesLoaded = false;
  /// True once getCategories() has completed (success or failure).
  bool _categoriesLoaded = false;
  /// All categories (any bucket) for dynamic category select.
  List<MockCategory> _allCategories = [];
  /// Set when getCategories() throws (e.g. network, RLS); user can retry.
  bool _categoriesLoadFailed = false;

  late AnimationController _entranceController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entranceController.forward();
      _loadPreferredParishes();
      _loadCategories();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredParishes() async {
    try {
      final ds = AppDataScope.of(context).dataSource;
      final ids = await UserParishPreferences.getPreferredParishIds();
      final list = await ds.getParishes();
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
    // Entrance already started in initState; no need to forward again.
  }

  /// Load all categories for dynamic category + tags (subcategory) select.
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _categoriesLoadFailed = false;
      _categoriesLoaded = false;
    });
    try {
      final ds = AppDataScope.of(context).dataSource;
      final categories = await ds.getCategories();
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
          _categoriesLoadFailed = true;
          _categoriesLoaded = true;
        });
      }
    }
  }

  /// Subcategories (tags) from the selected category only.
  List<MockSubcategory> get _selectedSubcategories {
    if (_selectedCategoryId == null) return [];
    for (final c in _allCategories) {
      if (c.id == _selectedCategoryId) return c.subcategories;
    }
    return [];
  }

  void _goToSlot() {
    if (_parishIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one preferred area.')),
      );
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category.')),
      );
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

  double _stagger(double begin, double end) {
    final t = _entranceController.value.clamp(0.0, 1.0);
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return Curves.easeOut.transform((t - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);
    final tHero = _stagger(0, 0.28);
    final tSubtitle = _stagger(0.12, 0.38);
    final tArea = _stagger(0.28, 0.52);
    final tCuisine = _stagger(0.45, 0.72);
    final tButton = _stagger(0.6, 0.88);
    final pulseScale = 1.0 + 0.04 * Curves.easeInOut.transform(_pulseController.value);
    final canGo = _parishIds.isNotEmpty && _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(
          'Choose for me',
          style: GoogleFonts.dancingScript(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: nav,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: nav,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 16 * (1 - tHero)),
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * tHero,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _kChooseForMeAsset,
                      fit: BoxFit.contain,
                      height: 160,
                      errorBuilder: (_, _, _) => const SizedBox(height: 160),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 12 * (1 - tSubtitle)),
                    child: child,
                  );
                },
                child: Text(
                  'Pick your preferred area, category, and optional tags—then tap to spin.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 14 * (1 - tArea)),
                    child: child,
                  );
                },
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
                    title: Text(
                      _parishesLoaded
                          ? (_parishIds.isEmpty
                              ? 'Preferred parish — Select at least one'
                              : _parishIds.length == 1
                                  ? 'Preferred parish — 1 selected'
                                  : 'Preferred parish — ${_parishIds.length} selected')
                          : 'Preferred parish',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                    subtitle: _parishesLoaded && _parishIds.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Tap to change areas',
                              style: theme.textTheme.bodySmall?.copyWith(color: sub),
                            ),
                          )
                        : null,
                    children: [
                      if (!_parishesLoaded)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _parishes.map((p) {
                            final selected = _parishIds.contains(p.id);
                            return TweenAnimationBuilder<double>(
                              key: ValueKey('${p.id}-$selected'),
                              tween: Tween(begin: 1, end: selected ? 1.04 : 1),
                              duration: const Duration(milliseconds: 120),
                              builder: (context, scale, child) => Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                              child: FilterChip(
                                label: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                    color: nav,
                                  ),
                                ),
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
                                selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                                side: BorderSide(
                                  color: selected ? AppTheme.specGold : nav.withValues(alpha: 0.25),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_categoriesLoadFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: sub),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Couldn\'t load categories.',
                          style: theme.textTheme.bodySmall?.copyWith(color: sub),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 12 * (1 - tCuisine)),
                    child: child,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_categoriesLoaded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading categories…',
                              style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                            ),
                          ],
                        ),
                      )
                    else if (_allCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'No categories available. Try again later.',
                          style: theme.textTheme.bodySmall?.copyWith(color: sub),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.specWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nav.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            hint: Text(
                              'Select a category',
                              style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: AppTheme.specWhite,
                            items: [
                              for (final c in _allCategories)
                                DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _selectedCategoryId == c.id ? FontWeight.w600 : FontWeight.w500,
                                      color: nav,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (id) => setState(() {
                              _selectedCategoryId = id;
                              _subcategoryIds = {};
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedSubcategories.isNotEmpty)
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 12 * (1 - tCuisine)),
                      child: child,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tags (optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _selectedSubcategories.map((s) {
                          final selected = _subcategoryIds.contains(s.id);
                          return TweenAnimationBuilder<double>(
                            key: ValueKey('${s.id}-$selected'),
                            tween: Tween(begin: 1, end: selected ? 1.04 : 1),
                            duration: const Duration(milliseconds: 120),
                            builder: (context, scale, child) => Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                            child: FilterChip(
                              label: Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: nav,
                                ),
                              ),
                              selected: selected,
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _subcategoryIds = Set.from(_subcategoryIds)..add(s.id);
                                } else {
                                  _subcategoryIds = Set.from(_subcategoryIds)..remove(s.id);
                                }
                              }),
                              backgroundColor: AppTheme.specWhite,
                              selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                              side: BorderSide(
                                color: selected ? AppTheme.specGold : nav.withValues(alpha: 0.25),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_selectedSubcategories.isNotEmpty) const SizedBox(height: 24),
              AnimatedBuilder(
                animation: Listenable.merge([_entranceController, _pulseController]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 14 * (1 - tButton)),
                    child: Transform.scale(
                      scale: canGo ? pulseScale : 1,
                      child: child,
                    ),
                  );
                },
                child: AppSecondaryButton(
                  onPressed: !canGo ? null : _goToSlot,
                  icon: const Icon(Icons.casino_rounded, size: 24),
                  label: Text(
                    'Pick for me',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
