import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// A linear depleting line for response-window games (ports `cs-core.jsx`'s
/// `Countdown`).
///
/// A 210×3 track whose ink fill shrinks from full to empty over [ms]
/// milliseconds (left-anchored, linear). The countdown restarts from full
/// whenever [trialKey] changes. Delegates its controller lifecycle to
/// [MotionDriver] (`playOnMount: true`, `trigger: trialKey`) so the controller
/// survives across trials and the lifecycle lives in one place.
///
/// Changing [ms] alone (without a new [trialKey]) re-targets the *next*
/// depletion's duration but does not restart the current one — games drive a
/// fresh window by bumping [trialKey], so this edge case is not reachable in
/// practice.
class Countdown extends StatelessWidget {
  /// Creates a countdown lasting [ms] milliseconds, restarting when [trialKey]
  /// changes.
  const Countdown({required this.ms, required this.trialKey, super.key});

  /// Duration of one depletion, in milliseconds.
  final int ms;

  /// Identity of the current trial; changing it restarts the depletion.
  final Object trialKey;

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: Duration(milliseconds: ms),
      playOnMount: true,
      trigger: trialKey,
      child: const ColoredBox(color: CsTokens.fg),
      builder: (context, animation, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 210,
            height: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (1 - animation.value).clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
