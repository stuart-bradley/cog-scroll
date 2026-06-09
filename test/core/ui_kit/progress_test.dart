import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

RichText _richOf(WidgetTester tester) => tester.widget<RichText>(
  find.descendant(of: find.byType(Progress), matching: find.byType(RichText)),
);

double _fillFactor(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  group('Progress', () {
    testWidgets('zero-pads the index and dims the "/ total" portion', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const Progress(idx: 8, total: 20)));
      final rich = _richOf(tester);
      expect(rich.text.toPlainText(), '08 / 20');

      // Text.rich nests the supplied span under a style-carrying root span.
      final root = rich.text as TextSpan;
      final inner = root.children!.first as TextSpan;
      final dim = inner.children![1] as TextSpan;
      expect(dim.style!.color!.a, lessThan(CsTokens.sub.a));
    });

    testWidgets('fills to idx/total at rest', (tester) async {
      await tester.pumpWidget(_wrap(const Progress(idx: 8, total: 20)));
      expect(_fillFactor(tester), closeTo(0.4, 1e-9));
    });

    testWidgets('eases the fill toward the new fraction on idx change', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const Progress(idx: 8, total: 20)));
      await tester.pumpWidget(_wrap(const Progress(idx: 16, total: 20)));
      await tester.pump(); // kick off the 200ms tween
      await tester.pump(const Duration(milliseconds: 200));
      expect(_fillFactor(tester), closeTo(0.8, 0.01));
    });
  });
}
