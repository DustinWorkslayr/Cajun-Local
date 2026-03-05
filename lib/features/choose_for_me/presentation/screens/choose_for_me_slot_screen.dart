import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/choose_for_me/presentation/widgets/choose_for_me_listing_card.dart';

/// Shows the "Choose for me" slot as a modal popup: listing cards spin in place and land on a random pick.
void showChooseForMeSlotDialog({
  required BuildContext context,
  required Set<String> parishIds,
  required Set<String> categoryIds,
  required Set<String> subcategoryIds,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, _) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: ChooseForMeSlotContent(
        parishIds: parishIds,
        categoryIds: categoryIds,
        subcategoryIds: subcategoryIds,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

/// Step 2 of "Choose for me": slot-machine style randomizer using Explore-style listing cards.
/// Shown in a popup; cards spin vertically and land on the winner.
class ChooseForMeSlotScreen extends StatefulWidget {
  const ChooseForMeSlotScreen({
    super.key,
    required this.parishIds,
    required this.categoryIds,
    required this.subcategoryIds,
  });

  final Set<String> parishIds;
  final Set<String> categoryIds;
  final Set<String> subcategoryIds;

  @override
  State<ChooseForMeSlotScreen> createState() => _ChooseForMeSlotScreenState();
}

class _ChooseForMeSlotScreenState extends State<ChooseForMeSlotScreen>
    with TickerProviderStateMixin {
  static const double _cardHeight = 100;
  static const double _viewportHeight = 120;
  static const int _slotItemsBeforeWinner = 28;
  static const int _slotItemsAfterWinner = 6;
  static const Duration _slotDuration = Duration(milliseconds: 4200);

  MockListing? _winner;
  bool _loadFailed = false;
  bool _loading = true;
  bool _spinning = true;
  bool _showResult = false;
  List<MockListing> _slotList = [];
  int _winnerSlotIndex = 0;
  late ScrollController _scrollController;
  late AnimationController _slotController;
  late Animation<double> _slotCurve;
  VoidCallback? _slotTickListener;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _slotController = AnimationController(
      vsync: this,
      duration: _slotDuration,
    );
    _slotCurve = CurvedAnimation(
      parent: _slotController,
      curve: Curves.easeOut,
    );
    _slotController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (_slotTickListener != null) {
          _slotController.removeListener(_slotTickListener!);
          _slotTickListener = null;
        }
      }
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _spinning = false;
          _showResult = true;
        });
      }
    });
    _loadAndSpin();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  static const Duration _loadTimeout = Duration(seconds: 10);

  /// Fetch listings for category + parish + subcategory. If parish filter yields none, retries without parish so category matches still show.
  Future<List<MockListing>> _fetchListingsForSlot() async {
    final ds = AppDataScope.of(context).dataSource;
    ListingFilters filters = ListingFilters(
      categoryIds: widget.categoryIds,
      parishIds: widget.parishIds,
      subcategoryIds: widget.subcategoryIds,
    );
    try {
      List<MockListing> listings = await ds.filterListings(filters).timeout(
        _loadTimeout,
        onTimeout: () => throw TimeoutException('Load timed out'),
      );
      if (listings.isNotEmpty) return listings;
      if (widget.parishIds.isEmpty) return listings;
      // Retry without parish filter so category matches still show (e.g. businesses with no parish set or parish ID mismatch).
      filters = ListingFilters(
        categoryIds: widget.categoryIds,
        parishIds: {},
        subcategoryIds: widget.subcategoryIds,
      );
      return ds.filterListings(filters).timeout(
        _loadTimeout,
        onTimeout: () => throw TimeoutException('Load timed out'),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _loadAndSpin() async {
    setState(() {
      _loadFailed = false;
      _loading = true;
    });
    try {
      List<MockListing> listings;
      try {
        listings = await _fetchListingsForSlot();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      if (listings.isEmpty) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
        return;
      }

      final rng = Random();
      final winner = listings[rng.nextInt(listings.length)];
      final others = listings.where((l) => l.id != winner.id).toList();
      final othersPool = others.isEmpty ? [winner] : others;

      final slotList = <MockListing>[];
      for (int i = 0; i < _slotItemsBeforeWinner; i++) {
        slotList.add(othersPool[rng.nextInt(othersPool.length)]);
      }
      slotList.add(winner);
      for (int i = 0; i < _slotItemsAfterWinner; i++) {
        slotList.add(othersPool[rng.nextInt(othersPool.length)]);
      }

      _winnerSlotIndex = _slotItemsBeforeWinner;
      setState(() {
        _winner = winner;
        _slotList = slotList;
        _loading = false;
        _spinning = true;
        _showResult = false;
      });

      if (!mounted) return;
      final paddingVertical = _viewportHeight - _cardHeight;
      final totalHeight = paddingVertical + slotList.length * _cardHeight + paddingVertical;
      final targetOffset = (_winnerSlotIndex * _cardHeight).clamp(0.0, totalHeight - _viewportHeight);

      _slotController.reset();
      if (_slotTickListener != null) {
        _slotController.removeListener(_slotTickListener!);
      }
      _slotTickListener = () {
        if (!_scrollController.hasClients) return;
        final value = _slotCurve.value;
        _scrollController.jumpTo(targetOffset * value);
      };
      _slotController.addListener(_slotTickListener!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!_scrollController.hasClients) return;
          _scrollController.jumpTo(0);
          _slotController.forward();
        });
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  void _spinAgain() {
    setState(() {
      _showResult = false;
      _loading = true;
    });
    _loadAndSpin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    if (_loadFailed) {
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: sub),
                const SizedBox(height: 16),
                Text(
                  'No data',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No places match your selection, or the request timed out. Try different areas or cuisine, or check your connection.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showSlot = _slotList.isNotEmpty;

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              _loading
                  ? 'Loading…'
                  : (_spinning ? 'Spinning…' : "You got…"),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _loading || _spinning ? sub : AppTheme.specGold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: _viewportHeight,
              child: _loading || !showSlot
                  ? Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: nav,
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: (_viewportHeight - _cardHeight) / 2,
                          bottom: (_viewportHeight - _cardHeight) / 2,
                        ),
                        itemCount: _slotList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              height: _cardHeight,
                              child: ChooseForMeListingCard(
                                listing: _slotList[index],
                                cardHeight: _cardHeight - 8,
                                onTap: null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            if (_showResult && _winner != null)
              _ResultActions(
                winner: _winner!,
                onSpinAgain: _spinAgain,
              ),
          ],
        ),
      ),
    );
  }
}

/// Slot content used inside the popup dialog: Explore-style cards that spin in place.
class ChooseForMeSlotContent extends StatefulWidget {
  const ChooseForMeSlotContent({
    super.key,
    required this.parishIds,
    required this.categoryIds,
    required this.subcategoryIds,
    this.onClose,
  });

  final Set<String> parishIds;
  final Set<String> categoryIds;
  final Set<String> subcategoryIds;
  final VoidCallback? onClose;

  @override
  State<ChooseForMeSlotContent> createState() => _ChooseForMeSlotContentState();
}

class _ChooseForMeSlotContentState extends State<ChooseForMeSlotContent>
    with TickerProviderStateMixin {
  static const double _cardHeight = 106;
  static const double _viewportHeight = 130;
  static const int _slotItemsBeforeWinner = 28;
  static const int _slotItemsAfterWinner = 6;
  static const Duration _slotDuration = Duration(milliseconds: 4200);
  static const double _maxTiltRadians = 0.35;

  MockListing? _winner;
  bool _loadFailed = false;
  bool _loading = true;
  bool _spinning = true;
  bool _showResult = false;
  List<MockListing> _slotList = [];
  Map<String, String> _subcategoryNames = {};
  int _winnerSlotIndex = 0;
  double _scrollOffset = 0;
  late ScrollController _scrollController;
  late AnimationController _slotController;
  late Animation<double> _slotCurve;
  VoidCallback? _slotTickListener;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _slotController = AnimationController(
      vsync: this,
      duration: _slotDuration,
    );
    _slotCurve = CurvedAnimation(
      parent: _slotController,
      curve: Curves.easeOut,
    );
    _slotController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (_slotTickListener != null) {
          _slotController.removeListener(_slotTickListener!);
          _slotTickListener = null;
        }
      }
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _spinning = false;
          _showResult = true;
        });
      }
    });
    _loadAndSpin();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  static const Duration _loadTimeout = Duration(seconds: 10);

  Future<void> _loadAndSpin() async {
    setState(() {
      _loadFailed = false;
      _loading = true;
    });
    try {
      final ds = AppDataScope.of(context).dataSource;
      try {
        final categories = await ds.getCategories();
        if (!mounted) return;
        final subMap = <String, String>{};
        for (final c in categories) {
          for (final s in c.subcategories) {
            subMap[s.id] = s.name;
          }
        }
        setState(() => _subcategoryNames = subMap);
      } catch (_) {
        if (!mounted) return;
        setState(() => _subcategoryNames = {});
      }
      if (!mounted) return;
      ListingFilters filters = ListingFilters(
        categoryIds: widget.categoryIds,
        parishIds: widget.parishIds,
        subcategoryIds: widget.subcategoryIds,
      );
      List<MockListing> listings;
      try {
        listings = await ds.filterListings(filters).timeout(
          _loadTimeout,
          onTimeout: () => throw TimeoutException('Load timed out'),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      if (listings.isEmpty && widget.parishIds.isNotEmpty) {
        try {
          filters = ListingFilters(
            categoryIds: widget.categoryIds,
            parishIds: {},
            subcategoryIds: widget.subcategoryIds,
          );
          listings = await ds.filterListings(filters).timeout(
            _loadTimeout,
            onTimeout: () => throw TimeoutException('Load timed out'),
          );
        } catch (_) {
          listings = [];
        }
      }
      if (!mounted) return;
      if (listings.isEmpty) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
        return;
      }

      final rng = Random();
      final winner = listings[rng.nextInt(listings.length)];
      final others = listings.where((l) => l.id != winner.id).toList();
      final othersPool = others.isEmpty ? [winner] : others;

      final slotList = <MockListing>[];
      for (int i = 0; i < _slotItemsBeforeWinner; i++) {
        slotList.add(othersPool[rng.nextInt(othersPool.length)]);
      }
      slotList.add(winner);
      for (int i = 0; i < _slotItemsAfterWinner; i++) {
        slotList.add(othersPool[rng.nextInt(othersPool.length)]);
      }

      _winnerSlotIndex = _slotItemsBeforeWinner;
      setState(() {
        _winner = winner;
        _slotList = slotList;
        _loading = false;
        _spinning = true;
        _showResult = false;
      });

      if (!mounted) return;
      final paddingVertical = _viewportHeight - _cardHeight;
      final totalHeight = paddingVertical + slotList.length * _cardHeight + paddingVertical;
      final targetOffset = (_winnerSlotIndex * _cardHeight).clamp(0.0, totalHeight - _viewportHeight);

      _slotController.reset();
      if (_slotTickListener != null) {
        _slotController.removeListener(_slotTickListener!);
      }
      _slotTickListener = () {
        if (!_scrollController.hasClients) return;
        final value = _slotCurve.value;
        final offset = targetOffset * value;
        _scrollController.jumpTo(offset);
        if (mounted && _scrollOffset != offset) {
          setState(() => _scrollOffset = offset);
        }
      };
      _slotController.addListener(_slotTickListener!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!_scrollController.hasClients) return;
          _scrollController.jumpTo(0);
          setState(() => _scrollOffset = 0);
          _slotController.forward();
        });
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  void _spinAgain() {
    setState(() {
      _showResult = false;
      _loading = true;
    });
    _loadAndSpin();
  }

  double _tiltForIndex(int index) {
    final paddingVertical = (_viewportHeight - _cardHeight) / 2;
    final cardCenter = paddingVertical + index * _cardHeight + _cardHeight / 2;
    final viewportCenter = _viewportHeight / 2;
    final delta = (viewportCenter - (cardCenter - _scrollOffset)) / _cardHeight;
    return (delta * _maxTiltRadians).clamp(-_maxTiltRadians, _maxTiltRadians);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    if (_loadFailed) {
      return Material(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose for me',
                    style: GoogleFonts.dancingScript(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: nav,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: nav,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Icon(Icons.inbox_rounded, size: 48, color: sub),
              const SizedBox(height: 16),
              Text(
                'No places match',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: nav,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different areas, category, or tags—or check your connection.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: sub),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                onPressed: widget.onClose,
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final showSlot = _slotList.isNotEmpty;

    return Material(
      color: AppTheme.specOffWhite,
      borderRadius: BorderRadius.circular(24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose for me',
                    style: GoogleFonts.dancingScript(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: nav,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: nav,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _loading
                    ? 'Loading…'
                    : (_spinning ? 'Spinning…' : "You got…"),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _loading || _spinning ? sub : AppTheme.specGold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _viewportHeight,
                child: _loading || !showSlot
                    ? Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: nav,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: (_viewportHeight - _cardHeight) / 2,
                            bottom: (_viewportHeight - _cardHeight) / 2,
                          ),
                          itemCount: _slotList.length,
                          itemBuilder: (context, index) {
                            final tilt = _tiltForIndex(index);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                height: _cardHeight,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateX(tilt),
                                  child: ExploreStyleListingCard(
                                    listing: _slotList[index],
                                    subcategoryNames: _subcategoryNames,
                                    cardHeight: _cardHeight - 6,
                                    cardRadius: 14,
                                    onTap: null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (_showResult && _winner != null)
                _ResultActions(
                  winner: _winner!,
                  onSpinAgain: _spinAgain,
                  onClose: widget.onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.winner,
    required this.onSpinAgain,
    this.onClose,
  });

  final MockListing winner;
  final VoidCallback onSpinAgain;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: onSpinAgain,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Spin again'),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              onClose?.call();
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => ListingDetailScreen(listingId: winner.id),
                ),
              );
            },
            expanded: false,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text('View listing'),
          ),
        ],
      ),
    );
  }
}
