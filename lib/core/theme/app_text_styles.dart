import 'package:flutter/material.dart';

/// Text styles the Material 3 `TextTheme` has no role for.
///
/// Widgets never set a font weight themselves; they take it from the
/// `TextTheme` or from here.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({required this.emphasis});

  static const standard = AppTextStyles(
    emphasis: TextStyle(fontWeight: FontWeight.w700),
  );

  /// Merged onto the surrounding style for a word that stands out inside a
  /// sentence, such as the target word in an example sentence.
  final TextStyle emphasis;

  static AppTextStyles of(BuildContext context) =>
      Theme.of(context).extension<AppTextStyles>()!;

  @override
  AppTextStyles copyWith({TextStyle? emphasis}) =>
      AppTextStyles(emphasis: emphasis ?? this.emphasis);

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) return this;
    return AppTextStyles(
      emphasis: TextStyle.lerp(emphasis, other.emphasis, t)!,
    );
  }
}
