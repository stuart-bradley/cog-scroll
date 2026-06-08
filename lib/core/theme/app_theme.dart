import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The single fixed pure-mono [ThemeData] for CogScroll.
///
/// There is no light/dark toggle and no Material You — mono is mono (SPEC §3.6).
abstract final class CsTheme {
  /// The one and only app theme.
  static ThemeData get theme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: CsTokens.fg,
      onPrimary: CsTokens.bg,
      secondary: CsTokens.fg,
      onSecondary: CsTokens.bg,
      error: CsTokens.fg,
      onError: CsTokens.bg,
      surface: CsTokens.bg,
      onSurface: CsTokens.fg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CsTokens.bg,
      fontFamily: CsType.family,
      textTheme: CsType.textTheme(),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
