import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/feedback.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

double _translationX(WidgetTester tester, Type within) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(within),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getTranslation()
    .x;

double _scale(WidgetTester tester, Type within) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(within),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  group('FeedbackMotion', () {
    Future<void> expectRoutes(
      WidgetTester tester,
      FeedbackKind kind,
      Type widgetType,
    ) async {
      await tester.pumpWidget(
        host(FeedbackMotion(kind: kind, child: stimulus)),
      );
      expect(find.byType(widgetType), findsOneWidget);
      expect(find.byKey(stimulusKey), findsOneWidget);
      await tester.pumpAndSettle();
    }

    testWidgets('routes each kind to its motion widget, keeping the child', (
      tester,
    ) async {
      await expectRoutes(tester, FeedbackKind.bloom, Bloom);
      await expectRoutes(tester, FeedbackKind.pulse, Pulse);
      await expectRoutes(tester, FeedbackKind.surge, Surge);
      await expectRoutes(tester, FeedbackKind.shake, Shake);
      await expectRoutes(tester, FeedbackKind.pop, Pop);
    });

    testWidgets('forwards surgeDirection to the underlying Surge', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FeedbackMotion(
            kind: FeedbackKind.surge,
            surgeDirection: SurgeDirection.left,
            trigger: 0,
            child: stimulus,
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          const FeedbackMotion(
            kind: FeedbackKind.surge,
            surgeDirection: SurgeDirection.left,
            trigger: 1,
            child: stimulus,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      // Default surge drives right (+50); forwarding `left` must yield -50.
      expect(_translationX(tester, Surge), closeTo(-50, 0.5));
    });

    testWidgets('forwards popVariant to the underlying Pop', (tester) async {
      await tester.pumpWidget(
        host(
          const FeedbackMotion(
            kind: FeedbackKind.pop,
            popVariant: PopVariant.big,
            child: stimulus,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      // The small (default) pop never exceeds 1.0; only `big` overshoots.
      expect(_scale(tester, Pop), greaterThan(1.0));
      await tester.pumpAndSettle();
    });
  });
}
