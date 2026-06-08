import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('line icons', () {
    testWidgets('Check paints without error', (tester) async {
      await tester.pumpWidget(const Center(child: Check()));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('Cross paints without error', (tester) async {
      await tester.pumpWidget(const Center(child: Cross()));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('size the paint box to the requested side length', (
      tester,
    ) async {
      await tester.pumpWidget(const Center(child: Check(size: 24)));
      expect(
        tester.widget<CustomPaint>(find.byType(CustomPaint)).size,
        const Size.square(24),
      );
    });
  });
}
