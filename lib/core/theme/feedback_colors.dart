import 'package:flutter/material.dart';

/// Answer-feedback colours, kept apart from the brand colours.
///
/// Red and green appear nowhere else in the app, so red always means a wrong
/// answer. Colour is never the only cue: feedback also carries an underline,
/// an icon or a result word.
@immutable
class FeedbackColors extends ThemeExtension<FeedbackColors> {
  const FeedbackColors({
    required this.correct,
    required this.accentOnly,
    required this.wrong,
  });

  static const light = FeedbackColors(
    correct: Color(0xFF1E7A3C),
    accentOnly: Color(0xFFA6520A),
    wrong: Color(0xFFC0362C),
  );

  static const dark = FeedbackColors(
    correct: Color(0xFF6FD08C),
    accentOnly: Color(0xFFF5B35C),
    wrong: Color(0xFFFF8F80),
  );

  /// Correct letters and the *Correct* result.
  final Color correct;

  /// Letters right apart from the accent, and the *Presque* result.
  final Color accentOnly;

  /// Wrong letters and the *Incorrect* result.
  final Color wrong;

  static FeedbackColors of(BuildContext context) =>
      Theme.of(context).extension<FeedbackColors>()!;

  @override
  FeedbackColors copyWith({Color? correct, Color? accentOnly, Color? wrong}) =>
      FeedbackColors(
        correct: correct ?? this.correct,
        accentOnly: accentOnly ?? this.accentOnly,
        wrong: wrong ?? this.wrong,
      );

  @override
  FeedbackColors lerp(FeedbackColors? other, double t) {
    if (other == null) return this;
    return FeedbackColors(
      correct: Color.lerp(correct, other.correct, t)!,
      accentOnly: Color.lerp(accentOnly, other.accentOnly, t)!,
      wrong: Color.lerp(wrong, other.wrong, t)!,
    );
  }
}
