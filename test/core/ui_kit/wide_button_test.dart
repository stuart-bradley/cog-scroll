import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(WideButton),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('WideButton', () {
    testWidgets('solid fills with ink, no border', (tester) async {
      await tester.pumpWidget(
        _wrap(WideButton(label: 'go', onPressed: () {})),
      );
      final decoration = _decorationOf(tester);
      expect(decoration.color, CsTokens.fg);
      expect(decoration.border, isNull);
    });

    testWidgets('hollow uses a white fill with an ink border', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WideButton(
            label: 'go',
            variant: WideButtonVariant.hollow,
            onPressed: () {},
          ),
        ),
      );
      final decoration = _decorationOf(tester);
      expect(decoration.color, CsTokens.bg);
      expect(decoration.border, isNotNull);
    });

    testWidgets('disabled (null onPressed) uses panel/faint and ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const WideButton(label: 'go')));
      expect(_decorationOf(tester).color, CsTokens.panel);
      final text = tester.widget<Text>(find.text('GO'));
      expect(text.style?.color, CsTokens.faint);

      // No GestureDetector is attached when disabled, so tapping is a no-op.
      await tester.tap(find.byType(WideButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(WideButton(label: 'go', onPressed: () => taps++)),
      );
      await tester.tap(find.byType(WideButton));
      expect(taps, 1);
    });

    testWidgets('renders the check icon when requested', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WideButton(
            label: 'ok',
            icon: WideButtonIcon.check,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(Check), findsOneWidget);
    });
  });
}
