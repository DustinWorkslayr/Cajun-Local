import 'package:flutter/material.dart';
import 'package:my_app/app/main_shell.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/listing_data_source.dart';
import 'package:my_app/core/data/repositories/favorites_repository.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/data/repositories/user_subscriptions_repository.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/subscription/user_tier_service.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/auth/presentation/screens/set_new_password_screen.dart';
import 'package:my_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root MaterialApp for Cajun Local.
class CajunLocalApp extends StatefulWidget {
  const CajunLocalApp({super.key});

  @override
  State<CajunLocalApp> createState() => _CajunLocalAppState();
}

class _CajunLocalAppState extends State<CajunLocalApp> {
  final ValueNotifier<Set<String>> _favoriteIds = ValueNotifier<Set<String>>({});
  final _dataSource = ListingDataSource();
  final _authRepository = AuthRepository();
  final _favoritesRepository = FavoritesRepository();
  final _subscriptionsRepository = UserSubscriptionsRepository();
  final _plansRepository = UserPlansRepository();
  late final UserTierService _userTierService = UserTierService(
    authRepository: _authRepository,
    subscriptionsRepository: _subscriptionsRepository,
    plansRepository: _plansRepository,
  );

  /// True when the user opened the app from a password reset link (recovery session).
  bool _isRecoverySession = false;

  @override
  void initState() {
    super.initState();
    _userTierService.refresh();
    _loadFavoritesWhenSignedIn();
    _authRepository.authStateChanges.listen((AuthState state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) setState(() => _isRecoverySession = true);
      }
      _userTierService.refresh();
      _loadFavoritesWhenSignedIn();
    });
  }

  Future<void> _loadFavoritesWhenSignedIn() async {
    if (!SupabaseConfig.isConfigured) return;
    if (_authRepository.currentUserId == null) {
      _favoriteIds.value = {};
      return;
    }
    final ids = await _favoritesRepository.list();
    _favoriteIds.value = ids.toSet();
  }

  @override
  void dispose() {
    _favoriteIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDataScope(
      dataSource: _dataSource,
      authRepository: _authRepository,
      favoritesRepository: _favoritesRepository,
      userTierService: _userTierService,
      child: FavoritesScope(
        favoriteIds: _favoriteIds,
        child: MaterialApp(
        title: 'Cajun Local',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          return UnconstrainedBox(
            child: SizedBox(width: size.width, height: size.height, child: child),
          );
        },
          home: Builder(
            builder: (context) {
              final auth = AppDataScope.of(context).authRepository;
              return StreamBuilder<AuthState>(
                stream: auth.authStateChanges,
                builder: (context, snapshot) {
                  if (!SupabaseConfig.isConfigured) {
                    return const SizedBox.expand(child: MainShell());
                  }
                  if (auth.currentUserId != null && _isRecoverySession) {
                    return SizedBox.expand(
                      child: SetNewPasswordScreen(
                        onPasswordUpdated: () {
                          setState(() => _isRecoverySession = false);
                        },
                      ),
                    );
                  }
                  if (auth.currentUserId != null) {
                    return const SizedBox.expand(child: MainShell());
                  }
                  return const SizedBox.expand(child: SignInScreen());
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
