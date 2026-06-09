import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Key on the sentinel stimulus, so tests can assert it stays in the tree.
const ValueKey<String> stimulusKey = ValueKey('motion-stimulus');

/// The sentinel stimulus every motion test wraps.
const Shape stimulus = Shape(id: 0, size: 60, key: stimulusKey);

/// Wraps [child] in a minimal app/scaffold for pumping.
Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
  debugShowCheckedModeBanner: false,
);

/// Builds a motion wrapping [stimulus] from the shared trigger/onComplete API.
typedef MotionFactory =
    Widget Function({Object? trigger, VoidCallback? onComplete});

/// The shared behavioural battery every feedback motion must pass.
///
/// [autoPlays] is true for motions that play on mount (bloom/pulse/pop) and
/// false for resting wrappers (surge/shake) that only start on a trigger
/// change. The first test is the regression guard for the non-negotiable rule
/// "the stimulus stays visible for the entire feedback motion".
void motionBattery({
  required String name,
  required MotionFactory build,
  required Duration duration,
  required bool autoPlays,
}) {
  group(name, () {
    testWidgets('keeps the stimulus visible for the whole motion', (
      tester,
    ) async {
      var done = 0;
      void complete() => done++;
      if (autoPlays) {
        await tester.pumpWidget(host(build(onComplete: complete)));
      } else {
        await tester.pumpWidget(
          host(build(trigger: 0, onComplete: complete)),
        );
        await tester.pumpWidget(
          host(build(trigger: 1, onComplete: complete)),
        );
        await tester.pump();
      }

      const steps = 12;
      final step = duration ~/ steps;
      for (var i = 0; i <= steps; i++) {
        expect(
          find.byKey(stimulusKey),
          findsOneWidget,
          reason: '$name: stimulus missing at step $i',
        );
        await tester.pump(step);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(done, 1, reason: '$name: onComplete should fire exactly once');
    });

    testWidgets('replays when the trigger changes', (tester) async {
      var done = 0;
      void complete() => done++;
      await tester.pumpWidget(host(build(trigger: 0, onComplete: complete)));
      await tester.pumpAndSettle();
      final afterFirst = done;

      await tester.pumpWidget(host(build(trigger: 1, onComplete: complete)));
      await tester.pumpAndSettle();

      expect(done, afterFirst + 1);
      expect(find.byKey(stimulusKey), findsOneWidget);
    });

    testWidgets('disposes cleanly when removed mid-motion', (tester) async {
      if (autoPlays) {
        await tester.pumpWidget(host(build()));
      } else {
        await tester.pumpWidget(host(build(trigger: 0)));
        await tester.pumpWidget(host(build(trigger: 1)));
      }
      await tester.pump(duration ~/ 3);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
