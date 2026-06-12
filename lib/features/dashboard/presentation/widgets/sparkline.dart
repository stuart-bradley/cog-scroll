import 'dart:math' as math;

import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Minimum value span the sparkline auto-scales to, so small fluctuations
/// aren't amplified into dramatic-looking swings (`cs-dashboard.jsx`).
const double _kMinSpan = 20;

/// The vertical bounds a sparkline maps its data into: the data's mid-point ±
/// half of `max(range, 20)`. Pure and exposed for tests.
@visibleForTesting
({double lo, double hi}) sparkBounds(List<int> data) {
  final lo = data.reduce(math.min).toDouble();
  final hi = data.reduce(math.max).toDouble();
  final mid = (lo + hi) / 2;
  final span = math.max(hi - lo, _kMinSpan);
  return (lo: mid - span / 2, hi: mid + span / 2);
}

/// A tiny auto-scaling sparkline of score [data] (oldest → newest), with a dot
/// on the most recent point. Renders an empty box under two points
/// (ports `cs-dashboard.jsx`'s `Spark`).
class Sparkline extends StatelessWidget {
  /// Creates a [width]×[height] sparkline over [data].
  const Sparkline({
    required this.data,
    this.width = 64,
    this.height = 22,
    super.key,
  });

  /// Score history, oldest first.
  final List<int> data;

  /// Sparkline width in logical pixels.
  final double width;

  /// Sparkline height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);
    return CustomPaint(size: Size(width, height), painter: _SparkPainter(data));
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.data);

  final List<int> data;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = sparkBounds(data);
    final range = bounds.hi - bounds.lo; // ≥ 20, never zero
    final w = size.width;
    final h = size.height;
    double x(int i) => (i / (data.length - 1)) * (w - 2) + 1;
    double y(int v) => (h - 2) - ((v - bounds.lo) / range) * (h - 4);

    final path = Path()..moveTo(x(0), y(data.first));
    for (var i = 1; i < data.length; i++) {
      path.lineTo(x(i), y(data[i]));
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = CsTokens.sub
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      )
      ..drawCircle(
        Offset(x(data.length - 1), y(data.last)),
        2.2,
        Paint()
          ..color = CsTokens.fg
          ..isAntiAlias = true,
      );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => !listEquals(old.data, data);
}
