import 'package:cogscroll/core/motion/motion_driver.dart';
import 'package:cogscroll/core/motion/motion_specs.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// Ring-bloom success feedback for round stimuli (DESIGN §3; ports the
/// prototype's `Bloom`).
///
/// Two concentric ink rings expand outward and fade over the wrapped [child],
/// which stays fully visible throughout. Plays on mount by default and again
/// whenever [trigger] changes; calls [onComplete] when each play settles.
class Bloom extends StatelessWidget {
  /// Wraps [child] with the ring-bloom motion.
  const Bloom({
    required this.child,
    this.trigger,
    this.onComplete,
    this.size = 212,
    this.playOnMount = true,
    super.key,
  });

  /// The stimulus the rings bloom around.
  final Widget child;

  /// Changing this replays the bloom.
  final Object? trigger;

  /// Called when a bloom finishes.
  final VoidCallback? onComplete;

  /// Resting diameter of the rings, in logical pixels.
  final double size;

  /// Play immediately on first build.
  final bool playOnMount;

  @override
  Widget build(BuildContext context) {
    return MotionDriver(
      duration: MotionDurations.bloom,
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
                painter: _BloomPainter(progress: animation.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BloomPainter extends CustomPainter {
  const _BloomPainter({required this.progress});

  final double progress;

  static const double _ring1End = 500 / 660;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.width / 2;
    final t = progress;

    // Outer ring: scale 0.62→1.5, opacity 0.85→0 over the first 500/660.
    final t1 = (t / _ring1End).clamp(0.0, 1.0);
    final c1 = MotionCurves.bloomRing1.transform(t1);
    _drawRing(canvas, center, base * _lerp(0.62, 1.5, c1), 7, 0.85 * (1 - c1));

    // Ghost ring: scale 0.62→1.78, opacity 0→0.5→0 over the whole timeline.
    final c2 = MotionCurves.bloomRing2.transform(t);
    final op2 = t < 0.3 ? 0.5 * (t / 0.3) : 0.5 * (1 - (t - 0.3) / 0.7);
    _drawRing(canvas, center, base * _lerp(0.62, 1.78, c2), 2, op2);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double width,
    double opacity,
  ) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = CsTokens.fg.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, paint);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_BloomPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
