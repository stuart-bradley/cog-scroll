import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// The six abstract stimuli used across CogScroll's games (DESIGN §2).
///
/// The declaration order matches the prototype's numeric shape ids
/// (`Shape({id})` in `cs-core.jsx`), so `CsShape.values[id]` bridges
/// integer-driven game engines to this type-safe enum.
enum CsShape {
  /// A filled disc.
  circle,

  /// A rounded square.
  square,

  /// An upward-pointing triangle.
  triangle,

  /// A four-pointed rhombus.
  diamond,

  /// A plus / cross glyph.
  cross,

  /// A flat-top hexagon.
  hexagon,
}

/// Human-readable names for the six shapes, indexed by [CsShape.index].
///
/// Ports the prototype's `SHAPE_NAMES` constant 1:1.
const List<String> kShapeNames = <String>[
  'Circle',
  'Square',
  'Triangle',
  'Diamond',
  'Cross',
  'Hexagon',
];

/// Paints one of the six [CsShape] stimuli into a 0..100 coordinate space
/// that is scaled to fill the available [Size].
///
/// When [outline] is true the shape is stroked (hollow) at a 6-unit width in
/// the 0..100 space — because the canvas is scaled before drawing, that stroke
/// scales with the rendered size exactly as the prototype's SVG does.
class ShapePainter extends CustomPainter {
  /// Creates a painter for [shape] in [color], stroked when [outline].
  const ShapePainter({
    required this.shape,
    this.color = CsTokens.fg,
    this.outline = false,
  });

  /// Which of the six stimuli to draw.
  final CsShape shape;

  /// Fill (or stroke, when [outline]) colour — defaults to ink.
  final Color color;

  /// Stroke the shape instead of filling it.
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round;
    if (outline) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
    } else {
      paint.style = PaintingStyle.fill;
    }

    canvas
      ..drawPath(_pathFor(shape), paint)
      ..restore();
  }

  Path _pathFor(CsShape shape) {
    switch (shape) {
      case CsShape.circle:
        return Path()
          ..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 47));
      case CsShape.square:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 6, 88, 88),
            const Radius.circular(7),
          ),
        );
      case CsShape.triangle:
        return Path()
          ..moveTo(50, 8)
          ..lineTo(92, 88)
          ..lineTo(8, 88)
          ..close();
      case CsShape.diamond:
        return Path()
          ..moveTo(50, 5)
          ..lineTo(95, 50)
          ..lineTo(50, 95)
          ..lineTo(5, 50)
          ..close();
      case CsShape.cross:
        // M37 7 h26 v30 h30 v26 h-30 v30 h-26 v-30 h-30 v-26 h30 z
        return Path()
          ..moveTo(37, 7)
          ..relativeLineTo(26, 0)
          ..relativeLineTo(0, 30)
          ..relativeLineTo(30, 0)
          ..relativeLineTo(0, 26)
          ..relativeLineTo(-30, 0)
          ..relativeLineTo(0, 30)
          ..relativeLineTo(-26, 0)
          ..relativeLineTo(0, -30)
          ..relativeLineTo(-30, 0)
          ..relativeLineTo(0, -26)
          ..relativeLineTo(30, 0)
          ..close();
      case CsShape.hexagon:
        // M50 6 L88 28 V72 L50 94 L12 72 V28 Z
        return Path()
          ..moveTo(50, 6)
          ..lineTo(88, 28)
          ..lineTo(88, 72)
          ..lineTo(50, 94)
          ..lineTo(12, 72)
          ..lineTo(12, 28)
          ..close();
    }
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.outline != outline;
}

/// A single CogScroll stimulus: one of the six [CsShape]s rendered in pure
/// black & white (DESIGN §2; ports `cs-core.jsx`'s `Shape`).
class Shape extends StatelessWidget {
  /// Creates a stimulus for shape [id] (0..5), sized [size] and drawn in
  /// [color]; pass `outline: true` for the hollow (stroked) form.
  const Shape({
    required this.id,
    this.size = 158,
    this.color = CsTokens.fg,
    this.outline = false,
    super.key,
  }) : assert(id >= 0 && id < 6, 'shape id must be in 0..5');

  /// Stimulus index into [CsShape.values] (0 circle … 5 hexagon).
  final int id;

  /// Side length of the square the shape is painted into, in logical pixels.
  final double size;

  /// Fill (or stroke, when [outline]) colour — defaults to ink.
  final Color color;

  /// Render the hollow (stroked) form instead of a solid fill.
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: ShapePainter(
        shape: CsShape.values[id],
        color: color,
        outline: outline,
      ),
    );
  }
}
