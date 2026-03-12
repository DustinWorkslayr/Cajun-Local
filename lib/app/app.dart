import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/app/main_shell.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/app_data_scope.dart';
import 'package:cajun_local/core/data/listing_data_source.dart';
import 'package:cajun_local/features/favorites/data/repositories/favorites_repository.dart';
import 'package:cajun_local/features/profile/data/repositories/user_plans_repository.dart';
import 'package:cajun_local/features/profile/data/repositories/user_subscriptions_repository.dart';
import 'package:cajun_local/core/revenuecat/revenuecat_service.dart';
import 'package:cajun_local/core/subscription/user_tier_service.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/screens/set_new_password_screen.dart';
import 'package:cajun_local/features/auth/presentation/screens/sign_in_screen.dart';

/// Root MaterialApp for Cajun Local.
class CajunLocalApp extends ConsumerStatefulWidget {
  const CajunLocalApp({super.key, this.revenueCatService});

  /// RevenueCat service (initialized in main). Null on web or if not configured.
  final RevenueCatService? revenueCatService;

  @override
  ConsumerState<CajunLocalApp> createState() => _CajunLocalAppState();
}

class _CajunLocalAppState extends ConsumerState<CajunLocalApp> {
  final _dataSource = ListingDataSource();
  final _favoritesRepository = FavoritesRepository();
  final _subscriptionsRepository = UserSubscriptionsRepository();
  final _plansRepository = UserPlansRepository();
  late final UserTierService _userTierService = UserTierService(
    subscriptionsRepository: _subscriptionsRepository,
    plansRepository: _plansRepository,
  );

  /// True when the user opened the app from a password reset link (recovery session).
  bool _isRecoverySession = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Handle auth changes for dependent services
    ref.listen(authControllerProvider, (previous, next) {
      final oldUser = previous?.valueOrNull;
      final newUser = next.valueOrNull;
      if (oldUser?.id != newUser?.id) {
        _userTierService.refresh(newUser?.id);
        if (newUser != null) {
          widget.revenueCatService?.logIn(newUser.id);
        }
      }
    });

    return AppDataScope(
      dataSource: _dataSource,
      favoritesRepository: _favoritesRepository,
      userTierService: _userTierService,
      revenueCatService: widget.revenueCatService,
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
        home: authState.when(
          data: (user) {
            if (user != null && _isRecoverySession) {
              return SizedBox.expand(
                child: SetNewPasswordScreen(
                  onPasswordUpdated: () {
                    setState(() => _isRecoverySession = false);
                  },
                ),
              );
            }
            if (user != null) {
              return const SizedBox.expand(child: MainShell());
            }
            return const SizedBox.expand(child: SignInScreen());
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        ),
      ),
    );
  }
}
