import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:flutter_test/flutter_test.dart';

import 'motion_test_kit.dart';

void main() {
  motionBattery(
    name: 'Bloom',
    build: ({trigger, onComplete}) =>
        Bloom(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.bloom,
    autoPlays: true,
  );

  testWidgets('a custom duration plays the bloom faster, stimulus visible', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      host(
        Bloom(
          duration: const Duration(milliseconds: 120),
          onComplete: () => done++,
          child: stimulus,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 70));
    expect(done, 0); // not finished before the custom duration
    expect(find.byKey(stimulusKey), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 70)); // total 140 > 120
    expect(done, 1);
  });
}
