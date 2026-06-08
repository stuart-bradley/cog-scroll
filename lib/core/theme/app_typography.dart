import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Space Grotesk type scale for CogScroll (DESIGN §2 / SPEC §3.6).
///
/// One family everywhere. Metrics and counters use tabular figures so
/// numerals stay column-aligned; chrome uses tracked uppercase micro-labels.
/// Every style sets its font family explicitly so `theme.textTheme` roles
/// resolve to the bundled font rather than the platform default.
abstract final class CsType {
  /// The single font family bundled under `assets/fonts/` (OFL).
  static const String family = 'Space Grotesk';

  /// Lining tabular figures — keeps numerals monospaced for metrics.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Large tabular metric (the RoundEnd hero number, ~92 logical px).
  static const TextStyle metric = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 92,
    height: 1,
    color: CsTokens.fg,
    fontFeatures: _tabular,
  );

  /// Tracked uppercase micro-label for chrome (letter-spacing ≈ 0.22em).
  static const TextStyle microLabel = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 12 * 0.22,
    color: CsTokens.sub,
  );

  /// Builds the app [TextTheme]; every role carries [family] and ink colour.
  static TextTheme textTheme() {
    return const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 32 / 24,
        color: CsTokens.fg,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        height: 28 / 22,
        color: CsTokens.fg,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 26 / 18,
        color: CsTokens.fg,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 22 / 16,
        color: CsTokens.fg,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 24 / 16,
        color: CsTokens.fg,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 20 / 14,
        color: CsTokens.sub,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 16 / 12,
        color: CsTokens.sub,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 20 / 14,
        color: CsTokens.fg,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        color: CsTokens.fg,
      ),
    );
  }
}
