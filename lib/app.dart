import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/services/app_settings_controller.dart';
import 'core/theme/app_theme.dart';

class NaubPadiApp extends StatelessWidget {
  const NaubPadiApp({super.key});

  static final GoRouter _router = AppRoutes.createRouter();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettingsController(),
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'NAUB Padi',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            routerConfig: _router,
            builder: (context, child) => child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
