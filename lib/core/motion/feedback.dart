import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:flutter/widgets.dart';

/// Which feedback motion a [FeedbackMotion] should play.
enum FeedbackKind {
  /// Ring bloom — [Bloom].
  bloom,

  /// Square pulse — [Pulse].
  pulse,

  /// Directional surge — [Surge].
  surge,

  /// Shake — [Shake].
  shake,

  /// Entrance pop — [Pop].
  pop,
}

/// A thin facade that routes to one of the five feedback motions by [kind],
/// forwarding the shared [child] / [trigger] / [onComplete] contract.
///
/// Named `FeedbackMotion` (not `Feedback`) to avoid colliding with Material's
/// `Feedback` helper. Lets a game pick a motion dynamically while preserving
/// the "stimulus always present" guarantee each underlying widget provides.
class FeedbackMotion extends StatelessWidget {
  /// Plays the [kind] motion around [child].
  const FeedbackMotion({
    required this.kind,
    required this.child,
    this.trigger,
    this.onComplete,
    this.surgeDirection = SurgeDirection.right,
    this.popVariant = PopVariant.small,
    super.key,
  });

  /// Which motion to play.
  final FeedbackKind kind;

  /// The stimulus the motion wraps.
  final Widget child;

  /// Changing this replays the motion.
  final Object? trigger;

  /// Called when the motion finishes.
  final VoidCallback? onComplete;

  /// Direction used when [kind] is [FeedbackKind.surge].
  final SurgeDirection surgeDirection;

  /// Variant used when [kind] is [FeedbackKind.pop].
  final PopVariant popVariant;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case FeedbackKind.bloom:
        return Bloom(trigger: trigger, onComplete: onComplete, child: child);
      case FeedbackKind.pulse:
        return Pulse(trigger: trigger, onComplete: onComplete, child: child);
      case FeedbackKind.surge:
        return Surge(
          direction: surgeDirection,
          trigger: trigger,
          onComplete: onComplete,
          child: child,
        );
      case FeedbackKind.shake:
        return Shake(trigger: trigger, onComplete: onComplete, child: child);
      case FeedbackKind.pop:
        return Pop(
          variant: popVariant,
          trigger: trigger,
          onComplete: onComplete,
          child: child,
        );
    }
  }
}
