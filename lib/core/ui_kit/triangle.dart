import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// Paints the small "better-means-up" delta triangle used by RoundEnd's score
/// delta and the dashboard's trend mark. [up] points the glyph up (improvement)
/// or down (regression); the glyph is defined in an 11-unit box and scales to
/// fill the [Size] it is given. Ports `cs-core.jsx`'s delta glyph paths.
class TrianglePainter extends CustomPainter {
  /// Creates a triangle pointing [up] (else down), filled with [color].
  const TrianglePainter({required this.up, this.color = CsTokens.fg});

  /// Whether the triangle points up (improvement) or down (regression).
  final bool up;

  /// Fill colour — defaults to ink.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 11);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    // up: M5.5 1 l4 7 h-8 z     down: M5.5 10 l4 -7 h-8 z
    final path = up
        ? (Path()
            ..moveTo(5.5, 1)
            ..lineTo(9.5, 8)
            ..lineTo(1.5, 8)
            ..close())
        : (Path()
            ..moveTo(5.5, 10)
            ..lineTo(9.5, 3)
            ..lineTo(1.5, 3)
            ..close());
    canvas
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(TrianglePainter old) => old.up != up || old.color != color;
}
