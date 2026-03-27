import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/choose_for_me/presentation/widgets/choose_for_me_listing_card.dart';

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
class ChooseForMeSlotScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ChooseForMeSlotScreen> createState() => _ChooseForMeSlotScreenState();
}

class _ChooseForMeSlotScreenState extends ConsumerState<ChooseForMeSlotScreen> with TickerProviderStateMixin {
  static const double _cardHeight = 100;
  static const double _viewportHeight = 120;
  static const int _slotItemsBeforeWinner = 28;
  static const int _slotItemsAfterWinner = 6;
  static const Duration _slotDuration = Duration(milliseconds: 4200);

  Business? _winner;
  bool _loadFailed = false;

  /// 'empty' = 0 results after fallbacks; 'error' = request threw (timeout/connection).
  String? _loadFailureReason;
  bool _loading = true;
  bool _spinning = true;
  bool _showResult = false;
  List<Business> _slotList = [];
  int _winnerSlotIndex = 0;

  /// Seconds remaining before "Spin again" is enabled (null = no cooldown).
  int? _spinAgainCooldownRemaining;
  Timer? _cooldownTimer;

  /// Revealed after a short delay when result is shown (for staggered fade-in).
  bool _resultActionsRevealed = false;
  late ScrollController _scrollController;
  late AnimationController _slotController;
  late Animation<double> _slotCurve;
  VoidCallback? _slotTickListener;

  static const int _spinAgainCooldownSeconds = 4;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _spinAgainCooldownRemaining = _spinAgainCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_spinAgainCooldownRemaining == null || _spinAgainCooldownRemaining! <= 1) {
          _spinAgainCooldownRemaining = null;
          t.cancel();
          _cooldownTimer = null;
        } else {
          _spinAgainCooldownRemaining = _spinAgainCooldownRemaining! - 1;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _slotController = AnimationController(vsync: this, duration: _slotDuration);
    _slotCurve = CurvedAnimation(parent: _slotController, curve: Curves.easeOut);
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
          _resultActionsRevealed = false;
        });
        _startCooldown();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _resultActionsRevealed = true);
        });
      }
    });
    // Defer load so context is fully initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAndSpin();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _scrollController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  static const Duration _loadTimeout = Duration(seconds: 25);

  /// Fetch listings for category + parish + subcategory. If parish filter yields none, retries without parish; if tags yield none, retries without subcategory.
  Future<List<Business>> _fetchListingsForSlot() async {
    if (kDebugMode) {
      debugPrint(
        '[ChooseForMe] fetch: categoryIds=${widget.categoryIds}, parishIds=${widget.parishIds}, subcategoryIds=${widget.subcategoryIds}',
      );
    }
    try {
      List<Business> listings = await BusinessRepository().listApproved(
        categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
        parishIds: widget.parishIds,
      ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
      if (kDebugMode) debugPrint('[ChooseForMe] first fetch: ${listings.length} listings');
      if (listings.isNotEmpty) return listings;
      if (widget.parishIds.isNotEmpty) {
        listings = await BusinessRepository().listApproved(
          categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
          parishIds: {},
        ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
        if (kDebugMode) debugPrint('[ChooseForMe] after parish fallback: ${listings.length} listings');
        if (listings.isNotEmpty) return listings;
      }
      if (widget.subcategoryIds.isNotEmpty) {
        listings = await BusinessRepository().listApproved(
          categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
          parishIds: widget.parishIds,
        ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
        if (kDebugMode) debugPrint('[ChooseForMe] after subcategory fallback: ${listings.length} listings');
      }
      return listings;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _loadAndSpin() async {
    setState(() {
      _loadFailed = false;
      _loadFailureReason = null;
      _loading = true;
    });
    try {
      List<Business> listings;
      try {
        listings = await _fetchListingsForSlot();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ChooseForMe] fetch threw: $e');
          debugPrintStack(stackTrace: st);
        }
        if (!mounted) return;
        setState(() {
          _loadFailed = true;
          _loadFailureReason = 'error';
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      if (listings.isEmpty) {
        if (kDebugMode) debugPrint('[ChooseForMe] showing "no match": 0 results after all fallbacks');
        setState(() {
          _loadFailed = true;
          _loadFailureReason = 'empty';
          _loading = false;
        });
        return;
      }

      final rng = Random();
      final winner = listings[rng.nextInt(listings.length)];
      final others = listings.where((l) => l.id != winner.id).toList();
      final othersPool = others.isEmpty ? [winner] : others;

      final slotList = <Business>[];
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

      void scheduleStartAnimation(int retriesLeft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
            _slotController.forward();
            return;
          }
          if (retriesLeft > 0) scheduleStartAnimation(retriesLeft - 1);
        });
      }

      scheduleStartAnimation(20);
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
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    setState(() {
      _showResult = false;
      _spinAgainCooldownRemaining = null;
      _resultActionsRevealed = false;
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
            style: GoogleFonts.dancingScript(fontSize: 26, fontWeight: FontWeight.w700, color: nav),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: nav),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadFailureReason == 'error'
                      ? 'Request failed or timed out. Check your connection.'
                      : 'No places match your filters. Try a different area or category.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(onPressed: () => Navigator.of(context).pop(), label: const Text('Back')),
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
          style: GoogleFonts.dancingScript(fontSize: 26, fontWeight: FontWeight.w700, color: nav),
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
              _loading ? 'Find local businesses with heart' : (_spinning ? 'Spinning…' : 'We chose…'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _loading || _spinning ? sub : AppTheme.specGold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: _viewportHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotSize = Size(constraints.maxWidth, _viewportHeight);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_loading || !showSlot)
                        Center(
                          child: _LoadingLocalBusinesses(textColor: sub, heartColor: nav, showLabel: false),
                        )
                      else
                        ClipRRect(
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
                              final isWinner = index == _winnerSlotIndex && _showResult && !_spinning;
                              final card = Padding(
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
                              if (isWinner) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 1.0, end: 1.08),
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.elasticOut,
                                  builder: (context, scale, child) => Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.center,
                                    child: _WinnerHighlight(child: child!),
                                  ),
                                  child: card,
                                );
                              }
                              return card;
                            },
                          ),
                        ),
                      if (_showResult && _winner != null)
                        Positioned.fill(
                          child: IgnorePointer(child: _CelebrationOverlay(size: slotSize)),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (_showResult && _winner != null)
              AnimatedOpacity(
                opacity: _resultActionsRevealed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _ResultActions(
                  winner: _winner!,
                  onSpinAgain: _spinAgain,
                  cooldownSecondsRemaining: _spinAgainCooldownRemaining,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Slot content used inside the popup dialog: Explore-style cards that spin in place.
class ChooseForMeSlotContent extends ConsumerStatefulWidget {
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
  ConsumerState<ChooseForMeSlotContent> createState() => _ChooseForMeSlotContentState();
}

class _ChooseForMeSlotContentState extends ConsumerState<ChooseForMeSlotContent> with TickerProviderStateMixin {
  static const double _cardHeight = 106;
  static const double _viewportHeight = 130;
  static const int _slotItemsBeforeWinner = 28;
  static const int _slotItemsAfterWinner = 6;
  static const Duration _slotDuration = Duration(milliseconds: 4200);
  static const double _maxTiltRadians = 0.35;

  Business? _winner;
  bool _loadFailed = false;

  /// 'empty' = 0 results after fallbacks; 'error' = request threw (timeout/connection).
  String? _loadFailureReason;
  bool _loading = true;
  bool _spinning = true;
  bool _showResult = false;
  List<Business> _slotList = [];
  Map<String, String> _subcategoryNames = {};
  int _winnerSlotIndex = 0;
  double _scrollOffset = 0;

  /// Seconds remaining before "Spin again" is enabled (null = no cooldown).
  int? _spinAgainCooldownRemaining;
  Timer? _cooldownTimer;

  /// Revealed after a short delay when result is shown (for staggered fade-in).
  bool _resultActionsRevealed = false;
  late ScrollController _scrollController;
  late AnimationController _slotController;
  late Animation<double> _slotCurve;
  VoidCallback? _slotTickListener;

  static const int _spinAgainCooldownSeconds = 4;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _spinAgainCooldownRemaining = _spinAgainCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_spinAgainCooldownRemaining == null || _spinAgainCooldownRemaining! <= 1) {
          _spinAgainCooldownRemaining = null;
          t.cancel();
          _cooldownTimer = null;
        } else {
          _spinAgainCooldownRemaining = _spinAgainCooldownRemaining! - 1;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _slotController = AnimationController(vsync: this, duration: _slotDuration);
    _slotCurve = CurvedAnimation(parent: _slotController, curve: Curves.easeOut);
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
          _resultActionsRevealed = false;
        });
        _startCooldown();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _resultActionsRevealed = true);
        });
      }
    });
    // Defer load so context is fully initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAndSpin();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _scrollController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  static const Duration _loadTimeout = Duration(seconds: 25);

  Future<void> _loadAndSpin() async {
    setState(() {
      _loadFailed = false;
      _loadFailureReason = null;
      _loading = true;
    });
    try {
      if (kDebugMode) {
        debugPrint(
          '[ChooseForMe] dialog fetch: categoryIds=${widget.categoryIds}, parishIds=${widget.parishIds}, subcategoryIds=${widget.subcategoryIds}',
        );
      }
      try {
        final categories = await ref.read(categoryRepositoryProvider).listCategories();
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
      List<Business> listings;
      try {
        listings = await BusinessRepository().listApproved(
          categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
          parishIds: widget.parishIds,
        ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
        if (kDebugMode) debugPrint('[ChooseForMe] dialog first fetch: ${listings.length} listings');
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ChooseForMe] dialog fetch threw: $e');
          debugPrintStack(stackTrace: st);
        }
        if (!mounted) return;
        setState(() {
          _loadFailed = true;
          _loadFailureReason = 'error';
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      if (listings.isEmpty && widget.parishIds.isNotEmpty) {
        try {
          listings = await BusinessRepository().listApproved(
            categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
            parishIds: {},
          ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
          if (kDebugMode) debugPrint('[ChooseForMe] dialog after parish fallback: ${listings.length} listings');
        } catch (_) {
          listings = [];
        }
      }
      if (!mounted) return;
      if (listings.isEmpty && widget.subcategoryIds.isNotEmpty) {
        try {
          listings = await BusinessRepository().listApproved(
            categoryId: widget.categoryIds.isEmpty ? null : widget.categoryIds.first,
            parishIds: widget.parishIds,
          ).timeout(_loadTimeout, onTimeout: () => throw TimeoutException('Load timed out'));
          if (kDebugMode) debugPrint('[ChooseForMe] dialog after subcategory fallback: ${listings.length} listings');
        } catch (_) {
          listings = [];
        }
      }
      if (!mounted) return;
      if (listings.isEmpty) {
        if (kDebugMode) debugPrint('[ChooseForMe] dialog showing "no match": 0 results after all fallbacks');
        setState(() {
          _loadFailed = true;
          _loadFailureReason = 'empty';
          _loading = false;
        });
        return;
      }

      final rng = Random();
      final winner = listings[rng.nextInt(listings.length)];
      final others = listings.where((l) => l.id != winner.id).toList();
      final othersPool = others.isEmpty ? [winner] : others;

      final slotList = <Business>[];
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

      void scheduleStartAnimation(int retriesLeft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
            setState(() => _scrollOffset = 0);
            _slotController.forward();
            return;
          }
          if (retriesLeft > 0) scheduleStartAnimation(retriesLeft - 1);
        });
      }

      scheduleStartAnimation(20);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ChooseForMe] dialog unexpected throw: $e');
        debugPrintStack(stackTrace: st);
      }
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loadFailureReason = 'error';
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
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    setState(() {
      _showResult = false;
      _spinAgainCooldownRemaining = null;
      _resultActionsRevealed = false;
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
                    style: GoogleFonts.dancingScript(fontSize: 22, fontWeight: FontWeight.w700, color: nav),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded), color: nav),
                ],
              ),
              const SizedBox(height: 24),
              Icon(Icons.inbox_rounded, size: 48, color: sub),
              const SizedBox(height: 16),
              Text(
                'No places match',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: nav),
              ),
              const SizedBox(height: 8),
              Text(
                _loadFailureReason == 'error'
                    ? 'Request failed or timed out. Check your connection.'
                    : 'No places match your filters. Try a different area or category.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: sub),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(onPressed: widget.onClose, label: const Text('Close')),
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
                    style: GoogleFonts.dancingScript(fontSize: 22, fontWeight: FontWeight.w700, color: nav),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded), color: nav),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _loading ? 'Find local businesses with heart' : (_spinning ? 'Spinning…' : 'We chose…'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _loading || _spinning ? sub : AppTheme.specGold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _viewportHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotSize = Size(constraints.maxWidth, _viewportHeight);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (_loading || !showSlot)
                          Center(
                            child: _LoadingLocalBusinesses(textColor: sub, heartColor: nav, showLabel: false),
                          )
                        else
                          ClipRRect(
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
                                final isWinner = index == _winnerSlotIndex && _showResult && !_spinning;
                                final card = Padding(
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
                                if (isWinner) {
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 1.0, end: 1.08),
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) => Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.center,
                                      child: _WinnerHighlight(child: child!),
                                    ),
                                    child: card,
                                  );
                                }
                                return card;
                              },
                            ),
                          ),
                        if (_showResult && _winner != null)
                          Positioned.fill(
                            child: IgnorePointer(child: _CelebrationOverlay(size: slotSize)),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_showResult && _winner != null)
                AnimatedOpacity(
                  opacity: _resultActionsRevealed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: _ResultActions(
                    winner: _winner!,
                    onSpinAgain: _spinAgain,
                    onClose: widget.onClose,
                    cooldownSecondsRemaining: _spinAgainCooldownRemaining,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User-friendly loading state for Choose for me: optional label + pulsing heart.
class _LoadingLocalBusinesses extends StatefulWidget {
  const _LoadingLocalBusinesses({this.textColor, this.heartColor, this.showLabel = true});

  final Color? textColor;
  final Color? heartColor;

  /// When false, only the pulsing heart is shown (title shows "Find local businesses with heart").
  final bool showLabel;

  @override
  State<_LoadingLocalBusinesses> createState() => _LoadingLocalBusinessesState();
}

class _LoadingLocalBusinessesState extends State<_LoadingLocalBusinesses> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.textColor ?? theme.colorScheme.onSurface;
    final heartColor = widget.heartColor ?? AppTheme.specGold;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.showLabel) ...[
          Text(
            'Loading local businesses',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulse.value,
              child: Icon(Icons.favorite_rounded, size: 40, color: heartColor),
            );
          },
        ),
      ],
    );
  }
}

/// Celebratory animated highlight for the winner card: breathing gold outline, glow, and scale pulse.
class _WinnerHighlight extends StatefulWidget {
  const _WinnerHighlight({required this.child});

  final Widget child;

  @override
  State<_WinnerHighlight> createState() => _WinnerHighlightState();
}

class _WinnerHighlightState extends State<_WinnerHighlight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.specGold;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final borderWidth = 2.5 + _glow.value * 2.5;
        final blurRadius = 12.0 + _glow.value * 16.0;
        final spreadRadius = _glow.value * 3.0;
        final shadowOpacity = 0.35 + _glow.value * 0.45;
        return Transform.scale(
          scale: _scale.value,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: shadowOpacity),
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
                BoxShadow(
                  color: gold.withValues(alpha: 0.15),
                  blurRadius: blurRadius * 1.5,
                  spreadRadius: spreadRadius + 2,
                ),
              ],
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(17), child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.winner, required this.onSpinAgain, this.onClose, this.cooldownSecondsRemaining});

  final Business winner;
  final VoidCallback onSpinAgain;
  final VoidCallback? onClose;

  /// When non-null and > 0, "Spin again" is disabled and shows countdown.
  final int? cooldownSecondsRemaining;

  @override
  Widget build(BuildContext context) {
    final canSpinAgain = cooldownSecondsRemaining == null || cooldownSecondsRemaining! <= 0;
    final spinLabel = (cooldownSecondsRemaining != null && cooldownSecondsRemaining! > 0)
        ? 'Spin again ($cooldownSecondsRemaining)'
        : 'Spin again';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: canSpinAgain ? onSpinAgain : null,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(spinLabel),
          ),
          const SizedBox(width: 12),
          AppPrimaryButton(
            onPressed: () {
              onClose?.call();
              context.push('/listing/${winner.id}');
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

/// Celebratory confetti overlay: continuous rain of circles, rectangles, and sparkles with rotation.
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({required this.size});

  final Size size;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  static const _celebratoryColors = [
    Color(0xFFF4B400), // specGold
    Color(0xFF0B2A55), // specNavy
    Color(0xFFFFFFFF), // white
    Color(0xFFFFF8E7), // champagne
    Color(0xFFFFD54F), // light gold
    Color(0xFFE3F2FD), // very light blue
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    final rng = Random();
    final w = widget.size.width;
    _particles = List.generate(90, (_) {
      final isRect = rng.nextBool();
      return _ConfettiParticle(
        offset: Offset(rng.nextDouble() * w, -20 - rng.nextDouble() * 60),
        velocity: Offset((rng.nextDouble() - 0.5) * 180, 120 + rng.nextDouble() * 140),
        color: _celebratoryColors[rng.nextInt(_celebratoryColors.length)],
        radius: 2.5 + rng.nextDouble() * 4,
        phase: rng.nextDouble(),
        rotationSpeed: (rng.nextDouble() - 0.5) * 12,
        isRect: isRect,
        size: isRect ? (4 + rng.nextDouble() * 8) : (3 + rng.nextDouble() * 5),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: widget.size,
          painter: _ConfettiPainter(
            progress: _controller.value,
            particles: _particles,
            viewHeight: widget.size.height,
            viewWidth: widget.size.width,
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.offset,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.phase,
    required this.rotationSpeed,
    required this.isRect,
    required this.size,
  });
  final Offset offset;
  final Offset velocity;
  final Color color;
  final double radius;
  final double phase;
  final double rotationSpeed;
  final bool isRect;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.viewHeight,
    required this.viewWidth,
  });

  final double progress;
  final List<_ConfettiParticle> particles;
  final double viewHeight;
  final double viewWidth;

  static const _velocityScale = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase) % 1.0;
      final dx = p.offset.dx + p.velocity.dx * t * _velocityScale;
      final dy = p.offset.dy + p.velocity.dy * t * _velocityScale;
      final rotation = t * p.rotationSpeed * pi;
      final opacity = (t < 0.85) ? 1.0 : ((1.0 - t) / 0.15).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.radius, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
