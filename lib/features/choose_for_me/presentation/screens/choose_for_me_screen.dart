import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/choose_for_me/presentation/widgets/restaurant_spin_wheel.dart';

/// Asset for the Choose for me hero illustration (selection screen).
const String _kChooseForMeAsset = 'assets/images/chooseforme.png';

/// "Choose for me" restaurant flow: parish + optional subcategory, then spin wheel
/// to pick a random restaurant from filtered results.
class ChooseForMeScreen extends StatefulWidget {
  const ChooseForMeScreen({super.key});

  @override
  State<ChooseForMeScreen> createState() => _ChooseForMeScreenState();
}

class _ChooseForMeScreenState extends State<ChooseForMeScreen> with TickerProviderStateMixin {
  Set<String> _parishIds = {};
  List<MockParish> _parishes = [];
  Set<String> _subcategoryIds = {};
  bool _parishesLoaded = false;
  MockCategory? _foodCategory;

  MockListing? _winner;
  List<String> _segmentLabels = [];
  int _winnerSegmentIndex = 0;
  double _rotation = 0;
  bool _spinning = false;
  bool _showResult = false;
  int? _highlightSegmentIndex;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  static const int _segmentCount = 8;
  static const int _fullTurns = 6;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _spinAnimation = CurvedAnimation(parent: _spinController, curve: Curves.easeOut);
    _spinController.addListener(() {
      if (mounted) setState(() => _rotation = _targetRotation * _spinAnimation.value);
    });
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _spinning = false;
          _showResult = true;
          _highlightSegmentIndex = _winnerSegmentIndex;
        });
      }
    });
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Start entrance animation immediately so the screen is never blank while data loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    _loadPreferredParishes();
    _loadCategories();
  }

  @override
  void dispose() {
    _spinController.dispose();
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
        _parishes = List<MockParish>.from(MockData.parishes);
        _parishesLoaded = true;
      });
    }
    // Entrance already started in initState; no need to forward again.
  }

  /// Use the "Food & dining" category for the spin wheel (by name or id).
  Future<void> _loadCategories() async {
    try {
      final ds = AppDataScope.of(context).dataSource;
      final categories = await ds.getCategories();
      if (!mounted) return;
      MockCategory? food;
      final nameLower = (String s) => s.toLowerCase().trim();
      for (final c in categories) {
        final n = nameLower(c.name);
        if (n == 'food & dining' || n == 'food and dining' || c.id == 'food') {
          food = c;
          break;
        }
      }
      food ??= categories.where((c) {
        final n = nameLower(c.name);
        return n.contains('food') || n.contains('dining') || n.contains('restaurant');
      }).firstOrNull;
      food ??= categories.isNotEmpty ? categories.first : null;
      if (!mounted) return;
      setState(() {
        _foodCategory = food;
      });
    } catch (_) {
      if (mounted) setState(() => _foodCategory = null);
    }
  }

  double _targetRotation = 0;

  Future<void> _spin() async {
    if (_parishIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one area.')),
      );
      return;
    }
    if (_foodCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food category not available.')),
      );
      return;
    }

    final ds = AppDataScope.of(context).dataSource;
    final filters = ListingFilters(
      categoryId: _foodCategory!.id,
      parishIds: _parishIds,
      subcategoryIds: _subcategoryIds,
    );
    List<MockListing> listings;
    try {
      listings = await ds.filterListings(filters);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load restaurants. Check your connection or try again later.'),
        ),
      );
      setState(() => _spinning = false);
      return;
    }
    if (!mounted) return;

    if (listings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No restaurants in your selection. Try different areas or subcategories.',
          ),
        ),
      );
      return;
    }

    final rng = Random();
    final winner = listings[rng.nextInt(listings.length)];
    _winnerSegmentIndex = rng.nextInt(_segmentCount);

    var others = listings.where((l) => l.id != winner.id).toList();
    if (others.isEmpty) others = [winner];
    others.shuffle(rng);

    final labels = List<String>.filled(_segmentCount, '');
    labels[_winnerSegmentIndex] = winner.name;
    int j = 0;
    for (int i = 0; i < _segmentCount; i++) {
      if (i != _winnerSegmentIndex) {
        labels[i] = others[j % others.length].name;
        j++;
      }
    }

    setState(() {
      _winner = winner;
      _segmentLabels = labels;
      _showResult = false;
      _highlightSegmentIndex = null;
      _spinning = true;
      _rotation = 0;
      _spinController.reset();
    });

    _targetRotation = 2 * pi * (_fullTurns + 1 - _winnerSegmentIndex / _segmentCount);
    _spinController.forward();
  }

  void _spinAgain() {
    setState(() {
      _showResult = false;
      _highlightSegmentIndex = null;
      _winner = null;
    });
    _spin();
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
    final canSpin = !_spinning && _parishIds.isNotEmpty;

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
                  'Unsure where to eat? Pick your area and spin.',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _parishIds = Set.from(_parishIds)..add(p.id);
                                } else {
                                  _parishIds = Set.from(_parishIds)..remove(p.id);
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
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _parishIds.isEmpty
                            ? 'Select at least one area.'
                            : 'Pre-filled from your preferred areas. Tap to change.',
                        style: theme.textTheme.bodySmall?.copyWith(color: sub),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_foodCategory != null && _foodCategory!.subcategories.isNotEmpty)
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
                        'Cuisine (optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _foodCategory!.subcategories.map((s) {
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
              if (_foodCategory != null && _foodCategory!.subcategories.isNotEmpty)
                const SizedBox(height: 24),
              AnimatedBuilder(
                animation: Listenable.merge([_entranceController, _pulseController]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 14 * (1 - tButton)),
                    child: Transform.scale(
                      scale: canSpin ? pulseScale : 1,
                      child: child,
                    ),
                  );
                },
                child: AppSecondaryButton(
                  onPressed: _spinning || _parishIds.isEmpty ? null : _spin,
                  icon: _spinning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.specWhite,
                          ),
                        )
                      : const Icon(Icons.casino_rounded, size: 24),
                  label: Text(
                    _spinning ? 'Spinning…' : 'Pick for me',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (_segmentLabels.isNotEmpty)
                RestaurantSpinWheel(
                  labels: _segmentLabels,
                  rotation: _rotation,
                  highlightSegmentIndex: _highlightSegmentIndex,
                  size: 280,
                ),
              if (_showResult && _winner != null)
                _ResultCard(winner: _winner!, onSpinAgain: _spinAgain),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.winner, required this.onSpinAgain});

  final MockListing winner;
  final VoidCallback onSpinAgain;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              "You got…",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.specGold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Material(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              shadowColor: Colors.black26,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingDetailScreen(listingId: widget.winner.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.winner.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      if (widget.winner.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.winner.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onSpinAgain,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Spin again'),
                          ),
                          const SizedBox(width: 8),
                          AppPrimaryButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ListingDetailScreen(listingId: widget.winner.id),
                                ),
                              );
                            },
                            expanded: false,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                            label: const Text('View listing'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
