import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// A check-mark glyph, stroked in [color] (ports `cs-core.jsx`'s `Check`).
///
/// Used inside button success affordances; drawn as a stroke so it keeps the
/// app's pure-mono, line-based identity rather than a filled Material icon.
class Check extends StatelessWidget {
  /// Creates a check-mark of side [size] drawn in [color] (defaults to ink).
  const Check({this.color = CsTokens.fg, this.size = 16, super.key});

  /// Stroke colour — defaults to ink so it reads on light grounds.
  final Color color;

  /// Side length of the square the glyph is painted into, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CheckPainter(color),
    );
  }
}

/// A cross / X glyph, stroked in [color] (ports `cs-core.jsx`'s `Cross`).
class Cross extends StatelessWidget {
  /// Creates a cross of side [size] drawn in [color] (defaults to ink).
  const Cross({this.color = CsTokens.fg, this.size = 15, super.key});

  /// Stroke colour — defaults to ink so it reads on light grounds.
  final Color color;

  /// Side length of the square the glyph is painted into, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrossPainter(color),
    );
  }
}

/// Shared stroke paint for the line icons (2.4 units, round caps and joins).
Paint _strokePaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.4
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Path defined in a 0..16 box (M3 8.5 l3.2 3.2 L13 4.5), scaled to fit.
    canvas
      ..save()
      ..scale(size.width / 16);
    final path = Path()
      ..moveTo(3, 8.5)
      ..lineTo(6.2, 11.7)
      ..lineTo(13, 4.5);
    canvas
      ..drawPath(path, _strokePaint(color))
      ..restore();
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Two strokes in a 0..15 box: (3.5,3.5)->(11.5,11.5) and the mirror.
    canvas
      ..save()
      ..scale(size.width / 15);
    final paint = _strokePaint(color);
    canvas
      ..drawLine(const Offset(3.5, 3.5), const Offset(11.5, 11.5), paint)
      ..drawLine(const Offset(11.5, 3.5), const Offset(3.5, 11.5), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => oldDelegate.color != color;
}
