import 'package:bah_francais/app/phone_layout.dart';
import 'package:bah_francais/app/router.dart';
import 'package:bah_francais/core/strings.g.dart';
import 'package:bah_francais/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BahApp extends ConsumerWidget {
  const BahApp({super.key});

  /// The app is in French only. Material's built-in text (tooltips, the
  /// text-selection menu, the licence page) follows this locale too.
  static const locale = Locale('fr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: Strings.commonAppName,
      debugShowCheckedModeBanner: false,
      // No themeMode yet: the default follows the phone's light/dark
      // setting until the Thème setting arrives (milestone 6).
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => PhoneLayout(child: child!),
    );
  }
}
