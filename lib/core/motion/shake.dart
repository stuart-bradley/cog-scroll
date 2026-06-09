import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:flutter/widgets.dart';

/// Shake feedback for a wrong answer (DESIGN §3; ports the prototype's
/// `.cs-shake`).
///
/// The wrapped [child] jitters left and right over 500ms and returns to rest.
/// At rest the child is untouched, so this safely wraps an always-present
/// stimulus; trigger it by changing [trigger]. (The prototype also switches the
/// shaken stimulus to its outline form — that swap is the game's job, kept out
/// of this pure transform.)
class Shake extends StatelessWidget {
  /// Wraps [child] with the shake motion.
  const Shake({
    required this.child,
    this.trigger,
    this.onComplete,
    this.playOnMount = false,
    this.duration,
    super.key,
  });

  /// The stimulus that shakes.
  final Widget child;

  /// Changing this replays the shake.
  final Object? trigger;

  /// Called when a shake finishes.
  final VoidCallback? onComplete;

  /// Play immediately on first build (off by default for a resting wrapper).
  final bool playOnMount;

  /// Override the play length (the offset curve is normalised, so a shorter
  /// duration just plays the same jitter faster). Defaults to
  /// [MotionDurations.shake]; fast-paced games pass a shorter window.
  final Duration? duration;

  // translateX keyframes (px) at normalised timeline stops.
  static const List<double> _stops = [0, 0.14, 0.28, 0.42, 0.57, 0.71, 0.85, 1];
  static const List<double> _offsets = [0, -12, 10, -8, 6, -4, 2, 0];

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: duration ?? MotionDurations.shake,
      trigger: trigger,
      onComplete: onComplete,
      playOnMount: playOnMount,
      child: child,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(_offsetAt(animation.value), 0),
          child: child,
        );
      },
    );
  }

  double _offsetAt(double t) {
    final p = Curves.easeInOut.transform(t);
    for (var i = 0; i < _stops.length - 1; i++) {
      if (p <= _stops[i + 1]) {
        final span = _stops[i + 1] - _stops[i];
        final seg = span == 0 ? 0.0 : (p - _stops[i]) / span;
        return _offsets[i] + (_offsets[i + 1] - _offsets[i]) * seg;
      }
    }
    return 0;
  }
}
