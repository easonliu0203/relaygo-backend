import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/providers/app_providers.dart';
import '../router/driver_router.dart';

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(driverRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Relay GO Driver',
      debugShowCheckedModeBanner: false,
      
      // 路由設定
      routerConfig: router,
      
      // 主題設定
      theme: AppTheme.lightTheme.copyWith(
        // 司機端專用主題調整
        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
          primary: const Color(0xFF4CAF50), // 綠色主題
        ),
      ),
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // 國際化設定
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      
      // 建構器
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
