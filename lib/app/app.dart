import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/app/router.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/data/providers/app_data_providers.dart';
import 'package:cajun_local/core/theme/theme.dart';

/// Root MaterialApp for Cajun Local.
class CajunLocalApp extends ConsumerStatefulWidget {
  const CajunLocalApp({super.key});

  @override
  ConsumerState<CajunLocalApp> createState() => _CajunLocalAppState();
}

class _CajunLocalAppState extends ConsumerState<CajunLocalApp> {
  @override
  Widget build(BuildContext context) {
    // Handle auth changes for dependent services
    ref.listen(authControllerProvider, (previous, next) {
      final oldUser = previous?.valueOrNull;
      final newUser = next.valueOrNull;
      if (oldUser?.id != newUser?.id) {
        if (newUser != null) {
          ref.read(revenueCatServiceProvider)?.logIn(newUser.id);
        }
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Cajun Local',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // First wrap with DevicePreview builder for frame/orientation
        final devChild = DevicePreview.appBuilder(context, child);
        
        final size = MediaQuery.sizeOf(context);
        return UnconstrainedBox(
          child: SizedBox(width: size.width, height: size.height, child: devChild),
        );
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}
