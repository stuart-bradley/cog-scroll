import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/ui_kit/radar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full score map (every domain measured).
Map<String, int?> _full() => {for (final d in Domains.all) d: 60};

/// A partial map — only the first two domains measured.
Map<String, int?> _partial() => {
  for (var i = 0; i < Domains.all.length; i++)
    Domains.all[i]: i < 2 ? 70 : null,
};

/// An all-null map (no data).
Map<String, int?> _empty() => {for (final d in Domains.all) d: null};

void main() {
  group('Radar', () {
    testWidgets('paints full / partial / empty score maps without error', (
      tester,
    ) async {
      for (final scores in [_full(), _partial(), _empty()]) {
        await tester.pumpWidget(Center(child: Radar(scores: scores)));
        expect(tester.takeException(), isNull);
        expect(find.byType(CustomPaint), findsOneWidget);
      }
    });

    testWidgets('paints a baseline ghost without error', (tester) async {
      await tester.pumpWidget(
        Center(
          child: Radar(
            scores: _full(),
            ghost: {for (final d in Domains.all) d: 40},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('sizes the paint box to the requested side length', (
      tester,
    ) async {
      await tester.pumpWidget(Center(child: Radar(scores: _full(), size: 250)));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(paint.size, const Size.square(250));
    });
  });

  group('radarHasData', () {
    test('is true when any domain is measured, false when all null', () {
      expect(radarHasData(_full()), isTrue);
      expect(radarHasData(_partial()), isTrue);
      expect(radarHasData(_empty()), isFalse);
    });
  });

  group('radarGhostVisible', () {
    test('false when ghost is absent or has no data', () {
      expect(radarGhostVisible(_full(), null), isFalse);
      expect(radarGhostVisible(_full(), _empty()), isFalse);
    });

    test('false when ghost is identical to current scores', () {
      expect(radarGhostVisible(_full(), _full()), isFalse);
    });

    test('true when a domain measured in both differs', () {
      final ghost = {for (final d in Domains.all) d: 40};
      expect(radarGhostVisible(_full(), ghost), isTrue);
    });

    test('false when the differing domain is unmeasured in current', () {
      // Ghost has data the current map lacks — not a "difference" to draw.
      final current = _empty();
      final ghost = {for (final d in Domains.all) d: 40};
      expect(radarGhostVisible(current, ghost), isFalse);
    });
  });

  group('RadarPainter.shouldRepaint', () {
    test('repaints when scores or ghost change, not when identical', () {
      final base = RadarPainter(scores: _full());
      expect(base.shouldRepaint(RadarPainter(scores: _partial())), isTrue);
      expect(
        base.shouldRepaint(RadarPainter(scores: _full(), ghost: _full())),
        isTrue,
      );
      expect(base.shouldRepaint(RadarPainter(scores: _full())), isFalse);
    });
  });
}
