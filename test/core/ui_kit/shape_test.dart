import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shape', () {
    testWidgets('paints every id in both fill and outline without error', (
      tester,
    ) async {
      for (var id = 0; id < CsShape.values.length; id++) {
        for (final outline in [false, true]) {
          await tester.pumpWidget(
            Center(
              child: Shape(id: id, outline: outline),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'id=$id outline=$outline should paint cleanly',
          );
          expect(find.byType(CustomPaint), findsOneWidget);
        }
      }
    });

    testWidgets('sizes the paint box to the requested side length', (
      tester,
    ) async {
      await tester.pumpWidget(const Center(child: Shape(id: 0, size: 80)));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(paint.size, const Size.square(80));
    });

    test('rejects out-of-range ids', () {
      expect(() => Shape(id: 6), throwsAssertionError);
      expect(() => Shape(id: -1), throwsAssertionError);
    });
  });

  group('kShapeNames', () {
    test('has one name per CsShape, in declaration order', () {
      expect(kShapeNames.length, CsShape.values.length);
      expect(kShapeNames.first, 'Circle');
      expect(kShapeNames[CsShape.hexagon.index], 'Hexagon');
    });
  });

  group('ShapePainter.shouldRepaint', () {
    const base = ShapePainter(shape: CsShape.circle);

    test('repaints when shape, colour, or outline changes', () {
      expect(
        base.shouldRepaint(const ShapePainter(shape: CsShape.square)),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const ShapePainter(shape: CsShape.circle, color: CsTokens.sub),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const ShapePainter(shape: CsShape.circle, outline: true),
        ),
        isTrue,
      );
    });

    test('does not repaint when nothing changes', () {
      expect(
        base.shouldRepaint(const ShapePainter(shape: CsShape.circle)),
        isFalse,
      );
    });
  });
}
