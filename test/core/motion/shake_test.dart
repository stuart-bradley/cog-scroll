import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

void main() {
  motionBattery(
    name: 'Shake',
    build: ({trigger, onComplete}) =>
        Shake(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.shake,
    autoPlays: false,
  );

  testWidgets('Shake leaves the stimulus at rest until triggered', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Shake(trigger: 0, child: stimulus)));
    // No trigger change yet: the wrapping Transform is the identity.
    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(Shake), matching: find.byType(Transform)),
    );
    expect(transform.transform.getTranslation().x, 0);
  });
}
