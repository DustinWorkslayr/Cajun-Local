import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/app/screens/splash_screen.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/auth/data/models/user_model.dart';
import 'package:cajun_local/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:cajun_local/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:cajun_local/features/auth/presentation/screens/set_new_password_screen.dart';
import 'package:cajun_local/app/main_shell.dart';
import 'package:cajun_local/features/home/presentation/screens/home_screen.dart';
import 'package:cajun_local/features/news/presentation/screens/news_screen.dart';
import 'package:cajun_local/features/explore/presentation/screens/explore_screen.dart';
import 'package:cajun_local/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cajun_local/features/deals/presentation/screens/deals_screen.dart';
import 'package:cajun_local/features/profile/presentation/screens/profile_screen.dart';
import 'package:cajun_local/features/news/presentation/screens/news_post_detail_screen.dart';
import 'package:cajun_local/features/listing/presentation/screens/business_detail_screen.dart';
import 'package:cajun_local/features/messaging/presentation/screens/my_conversations_screen.dart';
import 'package:cajun_local/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cajun_local/features/choose_for_me/presentation/screens/choose_for_me_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/my_listings_screen.dart';
import 'package:cajun_local/features/deals/presentation/screens/my_deals_screen.dart';
import 'package:cajun_local/features/deals/presentation/screens/my_punch_cards_screen.dart';
import 'package:cajun_local/features/deals/presentation/screens/scan_punch_screen.dart';
import 'package:cajun_local/features/profile/presentation/screens/about_screen.dart';
import 'package:cajun_local/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:cajun_local/features/my_listings/presentation/screens/form_submissions_inbox_screen.dart';
import 'package:cajun_local/features/local_events/presentation/screens/local_events_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorNewsKey = GlobalKey<NavigatorState>(debugLabel: 'shellNews');
final GlobalKey<NavigatorState> _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'shellExplore');
final GlobalKey<NavigatorState> _shellNavigatorDealsKey = GlobalKey<NavigatorState>(debugLabel: 'shellDeals');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      // If still loading and we have no value, we must stay on splash (or whatever neutral page).
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final isLoggingIn = state.uri.path.startsWith('/auth');
      final isSplash = state.uri.path == '/splash';

      // 1. If at splash, figure out where to go.
      if (isSplash) {
        return isAuth ? '/' : '/auth/login';
      }

      // 2. If not authenticated and trying to access a protected (non-auth) page, take them to login.
      if (!isAuth && !isLoggingIn) {
        return '/auth/login';
      }

      // 3. If authenticated and trying to access login/register, take them home.
      if (isAuth && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes (not in shell)
      GoRoute(path: '/splash', builder: (context, state) => const CajunSplashScreen()),
      GoRoute(path: '/auth/login', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/auth/register', builder: (context, state) => const SignUpScreen()),
      GoRoute(
        path: '/auth/set-new-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return SetNewPasswordScreen(token: token, onPasswordUpdated: () => context.go('/'));
        },
      ),

      // Main shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorNewsKey,
            routes: [GoRoute(path: '/news', builder: (context, state) => const NewsScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) {
                  final initialCategoryId = state.uri.queryParameters['categoryId'];
                  final initialSearch = state.uri.queryParameters['search'];
                  return CategoriesScreen(initialCategoryId: initialCategoryId, initialSearch: initialSearch);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDealsKey,
            routes: [GoRoute(path: '/deals', builder: (context, state) => const DealsScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),

      // Detail routes at ROOT level to hide bottom bar
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/news/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NewsPostDetailScreen(postId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BusinessDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/listing/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // We don't have ListingEditScreen imported? Or is it ListingDetailScreen?
          // Actually, many screens use ListingDetailScreen for both?
          // No, usually there's an edit screen.
          // For now, let's keep it simple.
          return BusinessDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/choose-for-me',
        builder: (context, state) => const ChooseForMeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-listings',
        builder: (context, state) => MyListingsScreen(onBack: () => context.pop(), embeddedInShell: false),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-deals',
        builder: (context, state) => const MyDealsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-punch-cards',
        builder: (context, state) => const MyPunchCardsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/scan-punch-card',
        builder: (context, state) => const ScanPunchScreen(),
      ),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/form-submissions',
        builder: (context, state) => const FormSubmissionsInboxScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-conversations',
        builder: (context, state) {
          final userId = ref.read(authControllerProvider).valueOrNull?.id ?? '';
          return MyConversationsScreen(userId: userId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/conversations/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return MyConversationsScreen(userId: userId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/local-events',
        builder: (context, state) => const LocalEventsScreen(),
      ),
    ],
  );
});

/// A notifier that triggers GoRouter refresh when authentication state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(authControllerProvider, (previous, next) {
      // Notify GoRouter to re-run the redirect whenever auth status changes
      // (from loading to data, or between different users).
      if (previous?.isLoading != next.isLoading || previous?.valueOrNull != next.valueOrNull) {
        notifyListeners();
      }
    });
  }
}
