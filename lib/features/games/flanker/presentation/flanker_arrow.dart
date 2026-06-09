import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:flutter/widgets.dart';

/// A single chevron arrow pointing [dir] (ports the prototype's `Arrow` SVG).
/// Shared by the Flanker intro legend and play surface.
class FlankerArrow extends StatelessWidget {
  /// Creates an arrow of side [size] pointing [dir], stroked in [color].
  const FlankerArrow({
    required this.dir,
    this.size = 48,
    this.color = CsTokens.fg,
    super.key,
  });

  /// Which way the chevron points.
  final FlankerDir dir;

  /// Side length of the square the arrow is painted into, in logical pixels.
  final double size;

  /// Stroke colour — defaults to ink.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ArrowPainter(dir: dir, color: color),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.dir, required this.color});

  final FlankerDir dir;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    // Left: M15 5 l-7 7 7 7 · Right: M9 5 l7 7 -7 7.
    final path = dir == FlankerDir.left
        ? (Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19))
        : (Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19));
    canvas
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.dir != dir || oldDelegate.color != color;
}
