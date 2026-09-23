import 'package:bah_francais/core/theme/app_text_styles.dart';
import 'package:bah_francais/core/theme/brand_colors.dart';
import 'package:bah_francais/core/theme/feedback_colors.dart';
import 'package:flutter/material.dart';

/// The app's light and dark themes: minimal Material 3, Poppins, brand
/// colours on a plain white or navy background.
///
/// Android dynamic colour is deliberately not used, so brand and feedback
/// colours always sit on predictable backgrounds.
abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static const fontFamily = 'Poppins';

  // The only weights bundled with the app.
  static const FontWeight _light = FontWeight.w300;
  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _bold = FontWeight.w700;

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _colorScheme(brightness);
    final base = ThemeData(colorScheme: colorScheme, fontFamily: fontFamily);
    final textTheme = _withWeights(base.textTheme);
    // A theme's text styles only get their sizes when Theme.of localises
    // them, but component styles below replace the defaults outright, so they
    // are built from this sized copy.
    final sized = base.typography.englishLike.merge(textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: _withWeights(base.primaryTextTheme),
      extensions: [
        if (brightness == Brightness.dark)
          FeedbackColors.dark
        else
          FeedbackColors.light,
        AppTextStyles.standard,
      ],
      // The main button: teal with a navy label in Poppins Light.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: sized.titleLarge!.copyWith(fontWeight: _light),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Teal is the colour of filled indicators.
        indicatorColor: colorScheme.primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => sized.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: BrandColors.teal,
          brightness: brightness,
        ).copyWith(
          primary: BrandColors.teal,
          onPrimary: BrandColors.navy,
          tertiary: BrandColors.yellow,
          onTertiary: BrandColors.navy,
          secondary: isDark ? BrandColors.blueOnDark : BrandColors.blue,
          onSecondary: isDark ? BrandColors.navy : BrandColors.white,
          surface: isDark ? BrandColors.navy : BrandColors.white,
          onSurface: isDark ? BrandColors.white : BrandColors.navy,
        );
    if (!isDark) return scheme;

    // Bars, cards and sheets sit on navy as slightly lighter shades of it,
    // rather than the seed's grey-teal.
    Color lighter(double amount) =>
        Color.lerp(BrandColors.navy, BrandColors.white, amount)!;
    return scheme.copyWith(
      surfaceDim: BrandColors.navy,
      surfaceBright: lighter(0.16),
      surfaceContainerLowest: Color.lerp(
        BrandColors.navy,
        const Color(0xFF000000),
        0.25,
      ),
      surfaceContainerLow: lighter(0.04),
      surfaceContainer: lighter(0.07),
      surfaceContainerHigh: lighter(0.10),
      surfaceContainerHighest: lighter(0.14),
    );
  }

  /// Poppins Light for large display text (every role here is 28 sp or
  /// more, since thin strokes are hard to read small), Bold for the result
  /// word and emphasis, Regular for everything else. Each role gets an
  /// explicit weight: Material's default Medium (500) is not bundled.
  static TextTheme _withWeights(TextTheme t) => t.copyWith(
    displayLarge: t.displayLarge!.copyWith(fontWeight: _light),
    displayMedium: t.displayMedium!.copyWith(fontWeight: _light),
    displaySmall: t.displaySmall!.copyWith(fontWeight: _light),
    headlineLarge: t.headlineLarge!.copyWith(fontWeight: _light),
    headlineMedium: t.headlineMedium!.copyWith(fontWeight: _light),
    headlineSmall: t.headlineSmall!.copyWith(fontWeight: _regular),
    titleLarge: t.titleLarge!.copyWith(fontWeight: _regular),
    titleMedium: t.titleMedium!.copyWith(fontWeight: _bold),
    titleSmall: t.titleSmall!.copyWith(fontWeight: _regular),
    bodyLarge: t.bodyLarge!.copyWith(fontWeight: _regular),
    bodyMedium: t.bodyMedium!.copyWith(fontWeight: _regular),
    bodySmall: t.bodySmall!.copyWith(fontWeight: _regular),
    labelLarge: t.labelLarge!.copyWith(fontWeight: _regular),
    labelMedium: t.labelMedium!.copyWith(fontWeight: _regular),
    labelSmall: t.labelSmall!.copyWith(fontWeight: _regular),
  );
}
