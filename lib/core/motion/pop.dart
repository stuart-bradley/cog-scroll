import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:flutter/widgets.dart';

/// Entrance-pop intensity.
enum PopVariant {
  /// A quick, subtle scale-in (0.9 → 1.03 → 1).
  small,

  /// A larger springy scale-in (0.86 → 1.13 → 1).
  big,
}

/// Entrance-pop feedback when a stimulus appears (DESIGN §3; ports the
/// prototype's `csPop` / `csPopBig`).
///
/// The wrapped [child] scales in with a slight overshoot, settling at full
/// size. Plays on mount by default (an entrance), and again when [trigger]
/// changes; calls [onComplete] when it settles.
class Pop extends StatelessWidget {
  /// Wraps [child] with the entrance-pop motion.
  const Pop({
    required this.child,
    this.variant = PopVariant.small,
    this.trigger,
    this.onComplete,
    this.playOnMount = true,
    super.key,
  });

  /// The stimulus that pops in.
  final Widget child;

  /// Pop intensity.
  final PopVariant variant;

  /// Changing this replays the pop.
  final Object? trigger;

  /// Called when a pop finishes.
  final VoidCallback? onComplete;

  /// Play immediately on first build.
  final bool playOnMount;

  @override
  Widget build(BuildContext context) {
    final big = variant == PopVariant.big;
    return MotionDriver(
      duration: big ? MotionDurations.popBig : MotionDurations.popSmall,
      trigger: trigger,
      onComplete: onComplete,
      playOnMount: playOnMount,
      child: child,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: _scaleAt(animation.value, big: big),
          child: child,
        );
      },
    );
  }

  /// Three-keyframe scale-in with an overshoot at the mid-point.
  ///
  /// The peak values (1.03 small / 1.13 big) reproduce the prototype's `csPop`
  /// / `csPopBig` keyframe waypoints directly — its visible bounce comes from
  /// those waypoints, not the timing function. Applying the spring cubic
  /// `(0.34,1.56,0.5,1)` to a plain 0.86→1 tween would peak near 1.01 and lose
  /// most of that bounce, so the keyframe form is kept for fidelity.
  double _scaleAt(double t, {required bool big}) {
    final p = Curves.easeOut.transform(t);
    final mid = big ? 0.55 : 0.6;
    final start = big ? 0.86 : 0.9;
    final peak = big ? 1.13 : 1.03;
    if (p <= mid) {
      return start + (peak - start) * (p / mid);
    }
    return peak + (1 - peak) * ((p - mid) / (1 - mid));
  }
}
