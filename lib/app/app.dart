import 'package:flutter/material.dart';
import 'package:my_app/app/main_shell.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/theme/theme.dart';

/// Root MaterialApp for Cajun Local.
class CajunLocalApp extends StatefulWidget {
  const CajunLocalApp({super.key});

  @override
  State<CajunLocalApp> createState() => _CajunLocalAppState();
}

class _CajunLocalAppState extends State<CajunLocalApp> {
  final ValueNotifier<Set<String>> _favoriteIds = ValueNotifier<Set<String>>({});

  @override
  void dispose() {
    _favoriteIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FavoritesScope(
      favoriteIds: _favoriteIds,
      child: MaterialApp(
        title: 'Cajun Local',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const MainShell(),
      ),
    );
  }
}
