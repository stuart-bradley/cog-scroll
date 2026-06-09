import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// Double square-pulse success feedback for cell/square stimuli (DESIGN §3;
/// ports the prototype's `Pulse`).
///
/// Two rounded-square ink outlines emanate (the second staggered 160ms) over
/// the wrapped [child], which stays fully visible. Plays on mount by default
/// and again when [trigger] changes; calls [onComplete] when each play settles.
class Pulse extends StatelessWidget {
  /// Wraps [child] with the double square-pulse motion.
  const Pulse({
    required this.child,
    this.trigger,
    this.onComplete,
    this.size = 170,
    this.playOnMount = true,
    super.key,
  });

  /// The stimulus the squares pulse around.
  final Widget child;

  /// Changing this replays the pulse.
  final Object? trigger;

  /// Called when a pulse finishes.
  final VoidCallback? onComplete;

  /// Resting side length of the squares, in logical pixels.
  final double size;

  /// Play immediately on first build.
  final bool playOnMount;

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: MotionDurations.pulse,
      trigger: trigger,
      onComplete: onComplete,
      playOnMount: playOnMount,
      child: child,
      builder: (context, animation, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            child,
            IgnorePointer(
              child: CustomPaint(
                size: Size.square(size),
                painter: _PulsePainter(progress: animation.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.progress});

  final double progress;

  // Each ring runs for 620ms inside the 780ms timeline; ring 2 starts at 160ms.
  static const double _ring1End = 620 / 780;
  static const double _ring2Start = 160 / 780;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.width;

    _drawRing(canvas, center, base, _ringProgress(progress, 0, _ring1End));
    _drawRing(canvas, center, base, _ringProgress(progress, _ring2Start, 1));
  }

  /// Eased 0..1 progress of one ring's window, or -1 before it starts.
  double _ringProgress(double t, double start, double end) {
    if (t < start) return -1;
    final local = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOut.transform(local);
  }

  void _drawRing(Canvas canvas, Offset center, double base, double eased) {
    if (eased < 0) return;
    final scale = _lerp(0.82, 1.62, eased);
    final opacity = 0.85 * (1 - eased);
    if (opacity <= 0) return;
    final side = base * scale;
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(20 * scale));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..color = CsTokens.fg.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..isAntiAlias = true;
    canvas.drawRRect(rrect, paint);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
