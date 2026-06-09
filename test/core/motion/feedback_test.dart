import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/feedback.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

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
  });
}
