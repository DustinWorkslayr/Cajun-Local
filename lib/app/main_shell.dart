import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/data/mock_data.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_managers_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/notifications/data/repositories/notifications_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/debug_agent_log.dart';
import 'package:cajun_local/features/profile/data/models/user_parish_preferences.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/categories/presentation/screens/categories_screen.dart';
import 'package:cajun_local/features/deals/presentation/screens/deals_screen.dart';
import 'package:cajun_local/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cajun_local/features/home/presentation/screens/home_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/my_listings_screen.dart';
import 'package:cajun_local/features/local_events/presentation/screens/local_events_screen.dart';
import 'package:cajun_local/features/messaging/presentation/screens/my_conversations_screen.dart';
import 'package:cajun_local/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cajun_local/features/profile/presentation/screens/profile_screen.dart';
import 'package:cajun_local/features/news/presentation/screens/news_screen.dart';
import 'package:cajun_local/features/news/presentation/screens/news_post_detail_screen.dart';
import 'package:cajun_local/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cajun_local/features/choose_for_me/presentation/screens/choose_for_me_screen.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/ask_local_sheet.dart';
import 'package:cajun_local/shared/widgets/explore_category_picker_dialog.dart';
import 'package:cajun_local/shared/widgets/parish_onboarding_dialog.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/bottom_nav_widget.dart';
import 'package:cajun_local/shared/widgets/quick_scan_sheet.dart';
/// Root scaffold with bottom navigation (Explore, Home, Favorites, Deals, Profile).
/// Home uses its own custom header; other tabs use AppBar. Bottom nav: 5 icons with Home in center. Ask Local in menu.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _exploreInitialCategoryId;
  bool _parishOnboardingChecked = false;
  final GlobalKey<NavigatorState> _newsNavigatorKey = GlobalKey<NavigatorState>();

  /// Incremented when parish onboarding completes so HomeScreen refetches (without being recreated).
  int _parishPrefsVersion = 0;
  bool _profileShowListings = false;
  bool _menuOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Active loyalty (punch) cards across businesses the current user manages. Null = not loaded.
  List<QuickScanLoyaltyCard>? _quickScanLoyaltyCards;

  /// Unread notifications count for app bar badge. Null = not loaded.
  Future<int>? _notificationsUnreadFuture;

  void _openMenu() {
    setState(() => _menuOpen = true);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  Future<void> _maybeShowParishOnboarding() async {
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    final done = await UserParishPreferences.hasCompletedParishOnboarding();
    if (!mounted || done) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ParishOnboardingDialog(
        onComplete: (ids) async {
          await UserParishPreferences.setPreferredParishIds(ids);
          await UserParishPreferences.setCompletedParishOnboarding();
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
    // Trigger home refetch after onboarding (parish prefs now set). HomeScreen refetches in place instead of being recreated.
    if (mounted) setState(() => _parishPrefsVersion++);
  }

  void _navigateToExploreWithCategory(MockCategory category) {
    setState(() {
      _currentIndex = 2; // Explore tab
      _exploreInitialCategoryId = category.id;
    });
  }

  void _navigateToExplore() {
    _showExploreCategoryPickerThenNavigate();
  }

  /// Switches to Explore tab immediately so the list starts loading, then shows the category picker
  /// on top. When the user selects, we apply the category and close the dialog (list keeps loading in background).
  Future<void> _showExploreCategoryPickerThenNavigate() async {
    // Switch to Explore tab first so CategoriesScreen mounts and starts loading the list.
    setState(() {
      _currentIndex = 2; // Explore tab
      _exploreInitialCategoryId = null;
    });
    final categories = await ref.read(categoryRepositoryProvider).listCategories();
    if (!mounted) return;
    final selectedId = await showExploreCategoryPickerDialog(context: context, categories: categories);
    if (!mounted) return;
    // null = user dismissed; keep Explore tab, leave category as-is (or all)
    if (selectedId != null) {
      setState(() {
        _exploreInitialCategoryId = selectedId == kExploreAllSentinel ? null : selectedId;
      });
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
    final uid = ref.watch(authControllerProvider).valueOrNull?.id;
    if (_quickScanLoyaltyCards == null && uid != null) {
      _loadQuickScanLoyaltyCards(uid);
    }
    if (_notificationsUnreadFuture == null && uid != null) {
      _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid);
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
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to view your messages.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MyConversationsScreen(userId: uid)));
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        parishPrefsVersion: _parishPrefsVersion,
        openMenu: _openMenu,
        onSelectCategory: _navigateToExploreWithCategory,
        onNavigateToExplore: _navigateToExplore,
        onNavigateToFavorites: () => setState(() => _currentIndex = 3),
        onNavigateToDeals: () => setState(() => _currentIndex = 4),
        onNavigateToNews: _goToNewsTab,
        onNavigateToNewsPost: _goToNewsPost,
        onOpenLocalEvents: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocalEventsScreen()));
        },
        onOpenChooseForMe: _onChooseForMeTap,
      ),
      Navigator(
        key: _newsNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(builder: (_) => const NewsScreen());
        },
      ),
      CategoriesScreen(initialCategoryId: _exploreInitialCategoryId),
      const FavoritesScreen(),
      const DealsScreen(),
      _profileShowListings
          ? MyListingsScreen(embeddedInShell: true, onBack: () => setState(() => _profileShowListings = false))
          : ProfileScreen(
              onMyListings: () => setState(() => _profileShowListings = true),
              onNavigateToHome: () => setState(() => _currentIndex = 0),
              onHandleNotificationActionUrl: (url) => _handleNotificationActionUrl(context, url),
            ),
    ];
  }

  /// Order: Home, News, Explore, Favorites, Deals, Profile (Home far left).
  static const List<String> _titles = ['Home', 'News', 'Explore', 'Favorites', 'Deals', 'Profile'];

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
    // For now, passing user.id as dummy token. Real token should be fetched if needed.
    if (user.id.isNotEmpty) {
      showAskLocalSheet(context, accessToken: user.id);
    }
  }

  void _onChooseForMeTap() {
    _closeMenu();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChooseForMeScreen()));
  }

  void _goToNewsTab() {
    setState(() => _currentIndex = 1);
  }

  void _goToNewsPost(String postId) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newsNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => NewsPostDetailScreen(postId: postId)),
      );
    });
  }

  /// Handles in-app action URLs from notifications (app://news/id, app://listings/id).
  /// Returns true if the URL was handled (caller should not launch externally).
  bool _handleNotificationActionUrl(BuildContext shellContext, String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    if (uri == null) return false;
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return false;
    final pathOnly = uri.path;
    // app://news/id -> host=news, pathSegments=[id]; /news/id -> pathSegments=[news, id]
    if ((uri.scheme == 'app' && uri.host == 'news') || pathOnly.startsWith('/news/')) {
      final postId = pathSegments.length >= 2 && pathSegments[0] == 'news' ? pathSegments[1] : pathSegments.last;
      if (postId.isEmpty) return false;
      Navigator.of(shellContext).pop();
      setState(() => _currentIndex = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _newsNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => NewsPostDetailScreen(postId: postId)),
        );
      });
      return true;
    }
    if ((uri.scheme == 'app' && uri.host == 'listings') || pathOnly.startsWith('/listings/')) {
      final listingId = pathSegments.length >= 2 && pathSegments[0] == 'listings' ? pathSegments[1] : pathSegments.last;
      if (listingId.isEmpty) return false;
      Navigator.of(shellContext).pop();
      setState(() => _currentIndex = 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          shellContext,
        ).push(MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: listingId)));
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_parishOnboardingChecked) {
      _parishOnboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowParishOnboarding());
    }
    final isHome = _currentIndex == 0;
    const profileTabIndex = 5;
    final isProfile = _currentIndex == profileTabIndex;
    final showListingsInProfile = isProfile && _profileShowListings;
    final screens = _buildScreens();
    // #region agent log
    agentLog('main_shell.dart:build', 'Scaffold building', {
      'currentIndex': _currentIndex,
      'screensLength': screens.length,
      'isHome': isHome,
    }, 'H1');
    // #endregion

    final scaffold = Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: false,
      appBar: AppBarWidget(
        title: showListingsInProfile ? 'My Listings' : _titles[_currentIndex],
        showBackButton: showListingsInProfile,
        onBack: () => setState(() => _profileShowListings = false),
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
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NotificationsScreen(onHandleActionUrl: (url) => _handleNotificationActionUrl(context, url)),
                  ),
                );
                if (!mounted) return;
                final uid = ref.read(authControllerProvider).valueOrNull?.id;
                if (uid != null) {
                  setState(() => _notificationsUnreadFuture = NotificationsRepository().unreadCount(uid));
                }
              });
            },
          ),
          IconButton(
            onPressed: _openMenu,
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: AlwaysStoppedAnimation<double>(_menuOpen ? 1 : 0),
              color: AppTheme.specNavy,
              size: 26,
            ),
            tooltip: 'Menu',
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: AppTheme.specOffWhite,
        child: _AppMenuDrawer(
          currentIndex: _currentIndex,
          onClose: _closeMenu,
          onNavigateToTab: (index) {
            _closeMenu();
            if (index == 2) {
              _showExploreCategoryPickerThenNavigate();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          onOpenAskLocal: _onAskLocalTap,
          onOpenChooseForMe: _onChooseForMeTap,
          onOpenLocalEvents: () {
            _closeMenu();
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocalEventsScreen()));
          },
          onOpenNotifications: () {
            _closeMenu();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    NotificationsScreen(onHandleActionUrl: (url) => _handleNotificationActionUrl(context, url)),
              ),
            );
          },
          onOpenMessages: _openMessages,
          onSignOut: _signOut,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // #region agent log
            final mediaH = MediaQuery.sizeOf(context).height;
            final mediaW = MediaQuery.sizeOf(context).width;
            final effectiveHeight = constraints.maxHeight > 0 ? constraints.maxHeight : (mediaH - kToolbarHeight);
            final effectiveWidth = constraints.maxWidth > 0 ? constraints.maxWidth : mediaW;
            agentLog('main_shell.dart:body', 'Body constraints', {
              'maxWidth': constraints.maxWidth,
              'maxHeight': constraints.maxHeight,
              'mediaHeight': mediaH,
              'mediaWidth': mediaW,
              'effectiveHeight': effectiveHeight,
              'effectiveWidth': effectiveWidth,
            }, 'H1');
            // #endregion
            // When parent gives zero height (e.g. Flutter web route), use OverflowBox so the child
            // gets effective size from MediaQuery and can render; we overflow the zero-sized slot.
            final isTablet = AppLayout.isTablet(context);
            const profileTabIndex = 4;
            final showFooter = !(isTablet && _currentIndex == profileTabIndex);
            final bottomNav = BottomNavWidget(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2) {
                  _showExploreCategoryPickerThenNavigate();
                } else {
                  setState(() => _currentIndex = index);
                }
              },
              screenCount: screens.length,
              titles: _titles,
            );
            final bodyChildren = <Widget>[
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: IndexedStack(key: ValueKey<int>(_currentIndex), index: _currentIndex, children: screens),
                ),
              ),
              if (showFooter) bottomNav,
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
                  child: Column(children: bodyChildren),
                ),
              );
            }
            return SizedBox(
              width: effectiveWidth,
              height: effectiveHeight,
              child: Column(children: bodyChildren),
            );
          },
        ),
      ),
    );
    return scaffold;
  }
}


class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppTheme.specGold : AppTheme.specNavy;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Side menu content: all pages, Ask Local, Local Events, Notifications, Messages, conditional Admin, Sign out.
class _AppMenuDrawer extends ConsumerStatefulWidget {
  const _AppMenuDrawer({
    required this.currentIndex,
    required this.onClose,
    required this.onNavigateToTab,
    required this.onOpenAskLocal,
    required this.onOpenChooseForMe,
    required this.onOpenLocalEvents,
    required this.onOpenNotifications,
    required this.onOpenMessages,
    required this.onSignOut,
  });

  final int currentIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenAskLocal;
  final VoidCallback onOpenChooseForMe;
  final VoidCallback onOpenLocalEvents;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenMessages;
  final VoidCallback onSignOut;

  @override
  ConsumerState<_AppMenuDrawer> createState() => _AppMenuDrawerState();
}

class _AppMenuDrawerState extends ConsumerState<_AppMenuDrawer> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Menu',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.specNavy,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavTile(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  selected: widget.currentIndex == 0,
                  onTap: () => widget.onNavigateToTab(0),
                ),
                _NavTile(
                  icon: Icons.article_rounded,
                  title: 'News',
                  selected: widget.currentIndex == 1,
                  onTap: () => widget.onNavigateToTab(1),
                ),
                _NavTile(
                  icon: Icons.explore_rounded,
                  title: 'Explore',
                  selected: widget.currentIndex == 2,
                  onTap: () => widget.onNavigateToTab(2),
                ),
                _NavTile(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
                  selected: widget.currentIndex == 3,
                  onTap: () => widget.onNavigateToTab(3),
                ),
                _NavTile(
                  icon: Icons.local_offer_rounded,
                  title: 'Deals',
                  selected: widget.currentIndex == 4,
                  onTap: () => widget.onNavigateToTab(4),
                ),
                _NavTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  selected: widget.currentIndex == 5,
                  onTap: () => widget.onNavigateToTab(5),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.support_agent_rounded, color: AppTheme.specGold),
                  title: Text(
                    'Ask Local',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('AI-powered local recommendations'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenAskLocal();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.casino_rounded, color: AppTheme.specGold),
                  title: Text(
                    'Choose for me',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Pick a random restaurant'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenChooseForMe();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Local Events',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Happenings from local businesses'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onClose();
                      widget.onOpenLocalEvents();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: AppTheme.specNavy),
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.specNavy),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenNotifications());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  subtitle: const Text('Conversations with businesses'),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenMessages());
                  },
                ),

                ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppTheme.specNavy),
                  title: Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSignOut());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
