import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(Pop), matching: find.byType(Transform)),
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  motionBattery(
    name: 'Pop',
    build: ({trigger, onComplete}) =>
        Pop(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.popSmall,
    autoPlays: true,
  );

  testWidgets('big variant overshoots above 1.0 then settles', (tester) async {
    await tester.pumpWidget(
      host(const Pop(variant: PopVariant.big, child: stimulus)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), greaterThan(1.0));

    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 1e-6));
  });
}
