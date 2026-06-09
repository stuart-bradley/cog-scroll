import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';

import 'motion_test_kit.dart';

void main() {
  motionBattery(
    name: 'Bloom',
    build: ({trigger, onComplete}) =>
        Bloom(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.bloom,
    autoPlays: true,
  );
}
