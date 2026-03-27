import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/notifications/data/repositories/notifications_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/ask_local_sheet.dart';
import 'package:cajun_local/shared/widgets/explore_category_picker_dialog.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/bottom_nav_widget.dart';
import 'package:cajun_local/shared/widgets/quick_scan_sheet.dart';
import 'widgets/app_menu_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  bool _parishOnboardingChecked = false;

  /// Incremented when parish onboarding completes so HomeScreen refetches (without being recreated).
  int _parishPrefsVersion = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Active loyalty (punch) cards across businesses the current user manages. Null = not loaded.
  List<QuickScanLoyaltyCard>? _quickScanLoyaltyCards;

  /// Unread notifications count for app bar badge. Null = not loaded.
  Future<int>? _notificationsUnreadFuture;

  void _closeMenu() {
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _maybeShowParishOnboarding() async {
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    final done = await UserParishPreferences.hasCompletedParishOnboarding();
    if (!mounted || done) return;
    final initialParishIds = await UserParishPreferences.getPreferredParishIds();
    final initialInterestIds = await UserParishPreferences.getPreferredInterestIds();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ParishOnboardingDialog(
        initialParishIds: initialParishIds,
        initialInterestIds: initialInterestIds,
        onComplete: (parishIds, interestIds) async {
          await UserParishPreferences.setPreferredParishIds(parishIds);
          await UserParishPreferences.setPreferredInterestIds(interestIds);
          await UserParishPreferences.setCompletedParishOnboarding();
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
    if (mounted) setState(() => _parishPrefsVersion++);
  }

  void _navigateToExploreWithCategory(String? categoryId) {
    if (categoryId != null) {
      context.go('/explore?categoryId=$categoryId');
    } else {
      context.go('/explore');
    }
  }

  Future<void> _showExploreCategoryPickerThenNavigate() async {
    final categories = await ref.read(categoryRepositoryProvider).listCategories();
    if (!mounted) return;
    final selectedId = await showExploreCategoryPickerDialog(context: context, categories: categories);
    if (!mounted) return;
    if (selectedId != null) {
      final id = selectedId == kExploreAllSentinel ? null : selectedId;
      _navigateToExploreWithCategory(id);
    } else {
      widget.navigationShell.goBranch(2);
    }
  }

  Future<void> _signOut() async {
    _closeMenu();
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      setState(() {
        _quickScanLoyaltyCards = null;
        _notificationsUnreadFuture = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.watch(authControllerProvider).valueOrNull;
    final uid = user?.id;

    if (uid != null) {
      if (_quickScanLoyaltyCards == null) {
        _loadQuickScanLoyaltyCards(uid);
      }
      if (_notificationsUnreadFuture == null) {
        _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid);
      }
    } else {
      // Clear data when user logs out
      _quickScanLoyaltyCards = null;
      _notificationsUnreadFuture = null;
    }
  }

  Future<void> _loadQuickScanLoyaltyCards(String uid) async {
    final managers = BusinessManagersRepository();
    final punchRepo = PunchCardProgramsRepository();
    final businessRepo = BusinessRepository();
    final bizIds = await managers.listBusinessIdsForUser(uid);
    final list = <QuickScanLoyaltyCard>[];
    for (final id in bizIds) {
      final programs = await punchRepo.listActive(businessId: id);
      final b = await businessRepo.getByIdForManager(id);
      final businessName = b?.name ?? id;
      for (final p in programs) {
        list.add(
          QuickScanLoyaltyCard(
            programId: p.id,
            programTitle: p.title?.trim().isNotEmpty == true ? p.title! : 'Untitled',
            businessName: businessName,
          ),
        );
      }
    }
    if (mounted) setState(() => _quickScanLoyaltyCards = list);
  }

  void _openQuickScan() {
    if (_quickScanLoyaltyCards == null || _quickScanLoyaltyCards!.isEmpty) return;
    showQuickScanSheet(context, loyaltyCards: _quickScanLoyaltyCards!);
  }

  void _openMessages() {
    _closeMenu();
    context.push('/my-conversations');
  }

  static const List<String> _titles = ['Home', 'News', 'Explore', 'Deals', 'Profile'];

  void _onAskLocalTap() {
    final user = ref.read(authControllerProvider).valueOrNull;
    final tierService = ref.read(userTierServiceProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to use Ask Local.')));
      return;
    }
    if (!(tierService.value?.canUseAskLocal ?? false)) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.specWhite,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ask Local is included with Cajun+ Membership and Pro',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'Get Cajun+ Membership for AI-powered local recommendations.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(onPressed: () => Navigator.of(ctx).pop(), expanded: false, child: const Text('Got it')),
            ],
          ),
        ),
      );
      return;
    }
    if (user.id.isNotEmpty) {
      showAskLocalSheet(context, accessToken: user.id);
    }
  }

  void _onChooseForMeTap() {
    _closeMenu();
    context.push('/choose-for-me');
  }

  @override
  Widget build(BuildContext context) {
    if (!_parishOnboardingChecked) {
      _parishOnboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowParishOnboarding());
    }
    final currentIndex = widget.navigationShell.currentIndex;
    const profileTabIndex = 4;
    final isProfile = currentIndex == profileTabIndex;
    final user = ref.watch(authControllerProvider).valueOrNull;

    final scaffold = Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.specOffWhite,
      extendBodyBehindAppBar: false,
      appBar: AppBarWidget(
        title: _titles[currentIndex],
        showBackButton: false, // Router handles back navigation
        actions: [
          if (_quickScanLoyaltyCards != null && _quickScanLoyaltyCards!.isNotEmpty)
            IconButton(
              onPressed: _openQuickScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              color: AppTheme.specNavy,
              tooltip: 'Quick scan punch card',
            ),
          NotificationsIconWidget(
            unreadFuture: _notificationsUnreadFuture,
            onOpen: () {
              context.push('/notifications').then((_) {
                if (!mounted) return;
                final uid = ref.read(authControllerProvider).valueOrNull?.id;
                if (uid != null) {
                  setState(() => _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid));
                }
              });
            },
          ),
          if (user != null)
            GestureDetector(
              onTap: () => widget.navigationShell.goBranch(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.specSurfaceContainerHigh,
                  child: Icon(Icons.person_rounded, size: 20, color: AppTheme.specNavy),
                ),
              ),
            ),
        ],
      ),
      drawer: AppMenuDrawer(
        currentIndex: currentIndex,
        onClose: _closeMenu,
        onNavigateToTab: (index) {
          _scaffoldKey.currentState?.closeDrawer();
          if (index == 2) {
            _showExploreCategoryPickerThenNavigate();
          } else {
            widget.navigationShell.goBranch(index);
          }
        },
        onOpenAskLocal: () {
          _scaffoldKey.currentState?.closeDrawer();
          _onAskLocalTap();
        },
        onOpenChooseForMe: () {
          _scaffoldKey.currentState?.closeDrawer();
          _onChooseForMeTap();
        },
        onOpenLocalEvents: () {
          _scaffoldKey.currentState?.closeDrawer();
          context.push('/local-events');
        },
        onOpenNotifications: () {
          _scaffoldKey.currentState?.closeDrawer();
          context.push('/notifications');
        },
        onOpenMessages: () {
          _scaffoldKey.currentState?.closeDrawer();
          _openMessages();
        },
        onSignOut: () {
          _scaffoldKey.currentState?.closeDrawer();
          _signOut();
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaH = MediaQuery.sizeOf(context).height;
          final mediaW = MediaQuery.sizeOf(context).width;
          final effectiveHeight = constraints.maxHeight > 0 ? constraints.maxHeight : (mediaH - kToolbarHeight);
          final effectiveWidth = constraints.maxWidth > 0 ? constraints.maxWidth : mediaW;

          final isTablet = AppLayout.isTablet(context);
          final showFooter = !(isTablet && isProfile);
          final bottomNav = BottomNavWidget(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == 2) {
                _showExploreCategoryPickerThenNavigate();
              } else {
                widget.navigationShell.goBranch(index);
              }
            },
            screenCount: _titles.length,
            titles: _titles,
          );

          final bodyChildren = <Widget>[
            // Body content takes full height
            Positioned.fill(child: widget.navigationShell),
            // Frosted glass nav bar floats at the bottom
            if (showFooter) Positioned(left: 0, right: 0, bottom: 0, child: bottomNav),
          ];

          if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
            return OverflowBox(
              minWidth: effectiveWidth,
              maxWidth: effectiveWidth,
              minHeight: effectiveHeight,
              maxHeight: effectiveHeight,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: effectiveWidth,
                height: effectiveHeight,
                child: Stack(children: bodyChildren),
              ),
            );
          }
          return SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: Stack(children: bodyChildren),
          );
        },
      ),
    );
    return scaffold;
  }
}
