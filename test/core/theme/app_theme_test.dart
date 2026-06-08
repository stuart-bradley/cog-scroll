import 'package:cogscroll/core/theme/app_theme.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsTheme', () {
    test('uses the pure-mono tokens', () {
      expect(CsTheme.theme.scaffoldBackgroundColor, CsTokens.bg);
      expect(CsTokens.bg, const Color(0xFFFFFFFF));
      expect(CsTokens.fg, const Color(0xFF111111));
      expect(CsTokens.panel, const Color(0xFFF4F4F4));
    });

    test('is a fixed light theme (no dark mode)', () {
      expect(CsTheme.theme.brightness, Brightness.light);
    });

    test('uses Space Grotesk across the text theme', () {
      expect(CsType.family, 'Space Grotesk');
      expect(CsTheme.theme.textTheme.bodyLarge?.fontFamily, 'Space Grotesk');
      expect(
        CsTheme.theme.textTheme.headlineMedium?.fontFamily,
        'Space Grotesk',
      );
    });

    test('metric style uses tabular figures', () {
      expect(
        CsType.metric.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
