import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

void main() {
  group('Label', () {
    testWidgets('renders its text upper-cased at weight 600', (tester) async {
      await tester.pumpWidget(_wrap(const Label('hello')));
      final text = tester.widget<Text>(find.text('HELLO'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('tracks letter-spacing at 0.22em of the size', (tester) async {
      await tester.pumpWidget(_wrap(const Label('go', size: 20)));
      final text = tester.widget<Text>(find.text('GO'));
      expect(text.style?.letterSpacing, 20 * 0.22);
    });

    testWidgets('defaults to secondary ink, honours an override', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const Label('a')));
      expect(tester.widget<Text>(find.text('A')).style?.color, CsTokens.sub);

      await tester.pumpWidget(_wrap(const Label('b', color: CsTokens.fg)));
      expect(tester.widget<Text>(find.text('B')).style?.color, CsTokens.fg);
    });
  });
}
