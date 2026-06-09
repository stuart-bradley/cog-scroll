import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/motion/pulse.dart';

import 'motion_test_kit.dart';

void main() {
  motionBattery(
    name: 'Pulse',
    build: ({trigger, onComplete}) =>
        Pulse(trigger: trigger, onComplete: onComplete, child: stimulus),
    duration: MotionDurations.pulse,
    autoPlays: true,
  );
}
