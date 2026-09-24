import 'package:bah_francais/core/theme/app_text_styles.dart';
import 'package:bah_francais/core/theme/app_theme.dart';
import 'package:bah_francais/core/theme/brand_colors.dart';
import 'package:bah_francais/core/theme/feedback_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

Map<String, TextStyle> roles(TextTheme t) => {
  'displayLarge': t.displayLarge!,
  'displayMedium': t.displayMedium!,
  'displaySmall': t.displaySmall!,
  'headlineLarge': t.headlineLarge!,
  'headlineMedium': t.headlineMedium!,
  'headlineSmall': t.headlineSmall!,
  'titleLarge': t.titleLarge!,
  'titleMedium': t.titleMedium!,
  'titleSmall': t.titleSmall!,
  'bodyLarge': t.bodyLarge!,
  'bodyMedium': t.bodyMedium!,
  'bodySmall': t.bodySmall!,
  'labelLarge': t.labelLarge!,
  'labelMedium': t.labelMedium!,
  'labelSmall': t.labelSmall!,
};

void main() {
  final themes = {'light': AppTheme.light, 'dark': AppTheme.dark};

  group('colour scheme', () {
    test('light: brand colours on a plain white background, navy text', () {
      final s = AppTheme.light.colorScheme;
      expect(s.brightness, Brightness.light);
      expect(s.primary, BrandColors.teal);
      expect(s.onPrimary, BrandColors.navy);
      expect(s.tertiary, BrandColors.yellow);
      expect(s.onTertiary, BrandColors.navy);
      expect(s.secondary, BrandColors.blue);
      expect(s.onSecondary, BrandColors.white);
      expect(s.surface, BrandColors.white);
      expect(s.onSurface, BrandColors.navy);
      expect(AppTheme.light.scaffoldBackgroundColor, BrandColors.white);
    });

    test('dark: navy background, white text, lighter blue', () {
      final s = AppTheme.dark.colorScheme;
      expect(s.brightness, Brightness.dark);
      expect(s.primary, BrandColors.teal);
      expect(s.onPrimary, BrandColors.navy);
      expect(s.tertiary, BrandColors.yellow);
      expect(s.onTertiary, BrandColors.navy);
      expect(s.secondary, BrandColors.blueOnDark);
      expect(s.onSecondary, BrandColors.navy);
      expect(s.surface, BrandColors.navy);
      expect(s.onSurface, BrandColors.white);
      expect(AppTheme.dark.scaffoldBackgroundColor, BrandColors.navy);
    });

    test('dark: surface containers are navy, getting lighter by level', () {
      final s = AppTheme.dark.colorScheme;
      final levels = [
        s.surfaceContainerLowest,
        s.surface,
        s.surfaceContainerLow,
        s.surfaceContainer,
        s.surfaceContainerHigh,
        s.surfaceContainerHighest,
      ].map((c) => c.computeLuminance()).toList();
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
      // Still dark enough for white text.
      expect(
        contrast(BrandColors.white, s.surfaceContainerHighest),
        greaterThanOrEqualTo(7),
      );
    });

    test('the navigation bar uses a teal indicator with a navy icon', () {
      for (final theme in themes.values) {
        final bar = theme.navigationBarTheme;
        expect(bar.indicatorColor, BrandColors.teal);
        final selected = bar.iconTheme!.resolve({WidgetState.selected})!;
        expect(selected.color, BrandColors.navy);
      }
    });
  });

  group('typography', () {
    for (final MapEntry(key: name, value: theme) in themes.entries) {
      test('$name: every role is Poppins in a bundled weight', () {
        final sized = ThemeData.localize(theme, theme.typography.englishLike);
        for (final textTheme in [
          theme.textTheme,
          theme.primaryTextTheme,
          // As Theme.of delivers it: the typography's default weights (some
          // Medium) must not come back.
          sized.textTheme,
          sized.primaryTextTheme,
        ]) {
          roles(textTheme).forEach((role, style) {
            expect(style.fontFamily, AppTheme.fontFamily, reason: role);
            expect(
              style.fontWeight,
              isIn([FontWeight.w300, FontWeight.w400, FontWeight.w700]),
              reason: role,
            );
          });
        }
      });

      test('$name: Light only at 16 sp or larger', () {
        // Sizes come from the typography, merged in the way Theme.of does.
        final sized = ThemeData.localize(theme, theme.typography.englishLike);
        roles(sized.textTheme).forEach((role, style) {
          if (style.fontWeight == FontWeight.w300) {
            expect(style.fontSize, greaterThanOrEqualTo(16), reason: role);
          }
        });
        final button = theme.filledButtonTheme.style!.textStyle!.resolve({})!;
        expect(button.fontWeight, FontWeight.w300);
        expect(button.fontSize, greaterThanOrEqualTo(16));
      });

      test('$name: display text Light, result word Bold, body Regular', () {
        final t = theme.textTheme;
        expect(t.displayLarge!.fontWeight, FontWeight.w300);
        expect(t.headlineMedium!.fontWeight, FontWeight.w300);
        expect(t.titleMedium!.fontWeight, FontWeight.w700);
        expect(t.titleLarge!.fontWeight, FontWeight.w400);
        expect(t.bodyLarge!.fontWeight, FontWeight.w400);
        expect(t.labelLarge!.fontWeight, FontWeight.w400);
      });

      // Component text styles replace the defaults outright, so they must
      // carry their own size rather than fall back to the ambient body text.
      test('$name: component text styles carry their own size', () {
        final geometry = theme.typography.englishLike;
        final button = theme.filledButtonTheme.style!.textStyle!.resolve({})!;
        expect(button.fontSize, geometry.titleLarge!.fontSize);
        expect(button.fontFamily, AppTheme.fontFamily);

        for (final states in [
          <WidgetState>{},
          {WidgetState.selected},
        ]) {
          final label = theme.navigationBarTheme.labelTextStyle!.resolve(
            states,
          )!;
          expect(label.fontSize, geometry.labelMedium!.fontSize);
          expect(label.fontWeight, FontWeight.w400);
          expect(label.fontFamily, AppTheme.fontFamily);
        }
      });

      test('$name: an emphasis style for words inside sentences', () {
        final styles = theme.extension<AppTextStyles>()!;
        expect(styles.emphasis.fontWeight, FontWeight.w700);
      });
    }
  });

  group('feedback colours', () {
    test('are the spec values, per theme', () {
      expect(AppTheme.light.extension<FeedbackColors>(), FeedbackColors.light);
      expect(AppTheme.dark.extension<FeedbackColors>(), FeedbackColors.dark);
      expect(FeedbackColors.light.correct, const Color(0xFF1E7A3C));
      expect(FeedbackColors.light.accentOnly, const Color(0xFFA6520A));
      expect(FeedbackColors.light.wrong, const Color(0xFFC0362C));
      expect(FeedbackColors.dark.correct, const Color(0xFF6FD08C));
      expect(FeedbackColors.dark.accentOnly, const Color(0xFFF5B35C));
      expect(FeedbackColors.dark.wrong, const Color(0xFFFF8F80));
    });

    test('copyWith and lerp', () {
      const red = Color(0xFFFF0000);
      final copy = FeedbackColors.light.copyWith(wrong: red);
      expect(copy.wrong, red);
      expect(copy.correct, FeedbackColors.light.correct);

      const light = FeedbackColors.light;
      const dark = FeedbackColors.dark;
      expect(light.lerp(dark, 0).correct, light.correct);
      expect(light.lerp(dark, 1).wrong, dark.wrong);
      expect(light.lerp(null, 0.5), same(light));
    });

    testWidgets('are read from the theme', (tester) async {
      late FeedbackColors colors;
      late AppTextStyles styles;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              colors = FeedbackColors.of(context);
              styles = AppTextStyles.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(colors, FeedbackColors.dark);
      expect(styles, AppTextStyles.standard);
    });
  });

  test('AppTextStyles copyWith and lerp', () {
    const italic = TextStyle(fontStyle: FontStyle.italic);
    expect(AppTextStyles.standard.copyWith(emphasis: italic).emphasis, italic);
    expect(
      AppTextStyles.standard.copyWith().emphasis.fontWeight,
      FontWeight.w700,
    );
    expect(
      AppTextStyles.standard.lerp(null, 0.5),
      same(AppTextStyles.standard),
    );
    expect(
      AppTextStyles.standard
          .lerp(AppTextStyles.standard, 0.5)
          .emphasis
          .fontWeight,
      FontWeight.w700,
    );
  });

  // The text and background pairs from the spec's Color scheme section, and
  // the ones the theme adds. WCAG AA for text is 4.5:1.
  group('contrast (WCAG AA, 4.5:1)', () {
    for (final MapEntry(key: name, value: theme) in themes.entries) {
      final s = theme.colorScheme;
      final feedback = theme.extension<FeedbackColors>()!;
      final pairs = <String, (Color, Color)>{
        'text on the background': (s.onSurface, s.surface),
        'secondary text on the background': (s.onSurfaceVariant, s.surface),
        'navy on teal (main button, selected tile)': (s.onPrimary, s.primary),
        'navy on yellow': (s.onTertiary, s.tertiary),
        'text on blue': (s.onSecondary, s.secondary),
        'blue as text or links on the background': (s.secondary, s.surface),
        'Correct feedback on the background': (feedback.correct, s.surface),
        'Presque feedback on the background': (feedback.accentOnly, s.surface),
        'Incorrect feedback on the background': (feedback.wrong, s.surface),
        'navigation labels on the bar': (s.onSurface, s.surfaceContainer),
        'unselected navigation labels on the bar': (
          s.onSurfaceVariant,
          s.surfaceContainer,
        ),
      };
      for (final MapEntry(key: pair, value: (foreground, background))
          in pairs.entries) {
        test('$name: $pair', () {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });
}
