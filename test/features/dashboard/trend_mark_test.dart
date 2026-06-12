import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/features/dashboard/presentation/widgets/trend_mark.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, DomainTrend trend) => tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: TrendMark(trend: trend),
  ),
);

void main() {
  group('TrendMark', () {
    testWidgets('none → "Not enough data yet" with no glyph', (tester) async {
      await _pump(tester, (state: TrendState.none, delta: 0, n: 1));
      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('improving → up triangle + IMPROVING', (tester) async {
      await _pump(tester, (state: TrendState.improving, delta: 7, n: 4));
      expect(find.byKey(const ValueKey(TrendState.improving)), findsOneWidget);
      expect(find.text('IMPROVING'), findsOneWidget);
    });

    testWidgets('declining → down triangle + DECLINING', (tester) async {
      await _pump(tester, (state: TrendState.declining, delta: -7, n: 4));
      expect(find.byKey(const ValueKey(TrendState.declining)), findsOneWidget);
      expect(find.text('DECLINING'), findsOneWidget);
    });

    testWidgets('stable → flat rule + STABLE', (tester) async {
      await _pump(tester, (state: TrendState.stable, delta: 1, n: 4));
      expect(find.byKey(const ValueKey(TrendState.stable)), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
      expect(find.text('STABLE'), findsOneWidget);
    });
  });
}
