import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps every screen.
///
/// Tablets are not a design target: on a wide screen the phone layout stays
/// in a centred column instead of stretching. It also keeps the status and
/// navigation bar icons readable on the white or navy background, since no
/// screen has an app bar to do it.
class PhoneLayout extends StatelessWidget {
  const PhoneLayout({required this.child, super.key});

  /// The widest the layout grows, in logical pixels.
  static const maxWidth = 480.0;

  /// Transparent status and navigation bars, so the plain background runs
  /// behind them, with icons that read on it. Android's contrast scrim is
  /// off: it would grey the bars over an already plain background.
  static SystemUiOverlayStyle systemBarsStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: iconBrightness,
      // iOS names the bar's background brightness instead of the icons'.
      statusBarBrightness: brightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarDividerColor: const Color(0x00000000),
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarContrastEnforced: false,
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsStyle(theme.brightness),
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
