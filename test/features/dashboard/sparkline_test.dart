import 'package:cogscroll/features/dashboard/presentation/widgets/sparkline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sparkBounds', () {
    test('clamps a narrow range to the minimum 20-point span', () {
      final b = sparkBounds([50, 52]);
      expect(b.lo, 41); // mid 51 − 10
      expect(b.hi, 61); // mid 51 + 10
    });

    test('uses the data range when it exceeds the minimum span', () {
      final b = sparkBounds([10, 90]);
      expect(b.lo, 10);
      expect(b.hi, 90);
    });

    test('centres a flat series on its value', () {
      final b = sparkBounds([70, 70, 70]);
      expect(b.lo, 60);
      expect(b.hi, 80);
    });
  });

  group('Sparkline', () {
    testWidgets('renders a painter with two or more points', (tester) async {
      await tester.pumpWidget(
        const Center(child: Sparkline(data: [40, 60, 80])),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an empty box under two points', (tester) async {
      await tester.pumpWidget(const Center(child: Sparkline(data: [42])));
      expect(find.byType(CustomPaint), findsNothing);
      final box = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(box.width, 64);
      expect(box.height, 22);
    });
  });
}
