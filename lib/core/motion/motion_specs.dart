import 'package:flutter/animation.dart';

/// Durations for CogScroll's five feedback motions, measured from the
/// prototype's CSS keyframes (DESIGN §3 / SPEC §3.7). Each duration spans the
/// *whole* motion, including any staggered second ring.
abstract final class MotionDurations {
  /// Ring bloom (correct, round stimulus) — outer ring 500ms, ghost 660ms.
  static const Duration bloom = Duration(milliseconds: 660);

  /// Square pulse (correct, cell stimulus) — 620ms ring + 160ms stagger.
  static const Duration pulse = Duration(milliseconds: 780);

  /// Directional surge (correct, Flanker).
  static const Duration surge = Duration(milliseconds: 500);

  /// Shake (any wrong answer).
  static const Duration shake = Duration(milliseconds: 500);

  /// Small entrance pop.
  static const Duration popSmall = Duration(milliseconds: 150);

  /// Large springy entrance pop.
  static const Duration popBig = Duration(milliseconds: 460);
}

/// Easing curves for the feedback motions (ported from the prototype's
/// `cubic-bezier` keyframe timings).
abstract final class MotionCurves {
  /// The outer bloom ring — a fast-out, gentle-settle cubic.
  static const Cubic bloomRing1 = Cubic(0.2, 0.8, 0.2, 1);

  /// The trailing ghost ring — a decelerating ease-out.
  static const Curve bloomRing2 = Curves.decelerate;
}
