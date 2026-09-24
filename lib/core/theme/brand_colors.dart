import 'package:flutter/painting.dart';

/// The brand colours from the spec's Color scheme section.
///
/// Colour carries meaning (which answer is selected, whether an answer was
/// right), never decoration. Widgets take colours from the theme; only the
/// theme reads these directly.
abstract final class BrandColors {
  /// Turquoise: the main button, the selected answer tile, filled indicators.
  /// Text on it is always [navy], never white (1.9:1).
  static const teal = Color(0xFF6EC9C8);

  /// Jaune: the symbol or label inside a selected tile, small highlights.
  /// Never used near the answer field, and never as text on white.
  static const yellow = Color(0xFFFACD3F);

  /// Bleu: unselected answer symbols, secondary icons, links. Light
  /// backgrounds only: it nearly disappears on navy.
  static const blue = Color(0xFF5172A1);

  /// Takes the place of [blue] on the navy dark-theme background.
  static const blueOnDark = Color(0xFF8FB0DB);

  /// The dark theme's background, and text on teal or yellow.
  static const navy = Color(0xFF14334C);

  static const white = Color(0xFFFFFFFF);
}
