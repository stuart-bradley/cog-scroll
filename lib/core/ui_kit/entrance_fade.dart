import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:flutter/widgets.dart';

/// Fades and lifts its [child] in once on first build (opacity 0→1,
/// translateY 6→0), matching the prototype's `csFade` entrance.
///
/// Delegates the controller lifecycle to [MotionDriver] (`playOnMount: true`,
/// no trigger) so the eager-controller/dispose conventions live in one place;
/// only the curved opacity/translate math lives here.
class EntranceFade extends StatelessWidget {
  /// Wraps [child] with a fade-and-rise entrance lasting [duration].
  const EntranceFade({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    super.key,
  });

  /// The content to reveal.
  final Widget child;

  /// How long the entrance takes.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: duration,
      playOnMount: true,
      child: child,
      builder: (context, animation, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
