import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:flutter/widgets.dart';

/// Direction a [Surge] drives toward.
enum SurgeDirection {
  /// Drive left.
  left,

  /// Drive right.
  right,
}

/// Directional-surge success feedback for the Flanker game (DESIGN §3; ports
/// the prototype's `.cs-surge-*`).
///
/// The wrapped [child] (the arrow row) slides 50px in [direction] and fades
/// out, reaching its final position at 60% of the timeline and holding there.
/// At rest the child is untouched, so this safely wraps an always-present
/// stimulus; trigger it by changing [trigger].
class Surge extends StatelessWidget {
  /// Wraps [child] with the directional-surge motion.
  const Surge({
    required this.child,
    this.direction = SurgeDirection.right,
    this.trigger,
    this.onComplete,
    this.playOnMount = false,
    super.key,
  });

  /// The stimulus that surges.
  final Widget child;

  /// Which way the surge drives.
  final SurgeDirection direction;

  /// Changing this replays the surge.
  final Object? trigger;

  /// Called when a surge finishes.
  final VoidCallback? onComplete;

  /// Play immediately on first build (off by default for a resting wrapper).
  final bool playOnMount;

  static const Interval _drive = Interval(0, 0.6, curve: Curves.easeIn);

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: MotionDurations.surge,
      trigger: trigger,
      onComplete: onComplete,
      playOnMount: playOnMount,
      child: child,
      builder: (context, animation, child) {
        final eased = _drive.transform(animation.value);
        final dx = (direction == SurgeDirection.right ? 50.0 : -50.0) * eased;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: 1 - eased, child: child),
        );
      },
    );
  }
}
