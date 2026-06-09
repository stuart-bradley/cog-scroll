import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

double _translationX(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(Surge), matching: find.byType(Transform)),
    )
    .transform
    .getTranslation()
    .x;

void main() {
  motionBattery(
    name: 'Surge',
    build: ({trigger, onComplete}) =>
        Surge(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.surge,
    autoPlays: false,
  );

  testWidgets('reaches its final offset by 60% and holds there', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Surge(trigger: 0, child: stimulus)));
    await tester.pumpWidget(host(const Surge(trigger: 1, child: stimulus)));
    await tester.pump();

    // Mid-ramp (30%): the easeIn interval is still climbing, so the offset must
    // be strictly between rest and the final 50px — this pins the ramp shape,
    // not just the held value.
    await tester.pump(const Duration(milliseconds: 150));
    final atThirty = _translationX(tester);
    expect(atThirty, greaterThan(0));
    expect(atThirty, lessThan(50));

    await tester.pump(const Duration(milliseconds: 200)); // now at 70% of 500ms
    final atSeventy = _translationX(tester);
    await tester.pump(const Duration(milliseconds: 100)); // 90%
    final atNinety = _translationX(tester);

    expect(atSeventy, closeTo(50, 0.5));
    expect(atNinety, closeTo(50, 0.5));
  });

  testWidgets('drives left for SurgeDirection.left', (tester) async {
    await tester.pumpWidget(
      host(
        const Surge(
          trigger: 0,
          direction: SurgeDirection.left,
          child: stimulus,
        ),
      ),
    );
    await tester.pumpWidget(
      host(
        const Surge(
          trigger: 1,
          direction: SurgeDirection.left,
          child: stimulus,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(_translationX(tester), closeTo(-50, 0.5));
  });
}
