import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:flutter/widgets.dart';

/// The Trail Making intro: a small connected-dots legend, the (mode-specific)
/// rule, and a Start button.
class TrailsIntro extends StatelessWidget {
  /// Creates the intro for [mode] with this round's target [count].
  const TrailsIntro({
    required this.mode,
    required this.count,
    required this.onStart,
    super.key,
  });

  /// Mode A (numbers) or Mode B (number/letter alternation).
  final TrailMode mode;

  /// Targets this round (from the difficulty level).
  final int count;

  /// Start handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final modeB = mode == TrailMode.b;
    return Intro(
      text: modeB
          ? 'Tap in switching order — 1, A, 2, B, 3, C — as fast as you can.'
          : 'Tap the numbers in order, 1 to $count, as fast as you can.',
      startLabel: 'Start',
      footnote: modeB
          ? 'Alternate numbers & letters · against the clock'
          : 'Connect 1 – $count · against the clock',
      onStart: onStart,
      legend: const CustomPaint(
        size: Size(80, 40),
        painter: _LegendPainter(),
      ),
    );
  }
}

/// The intro legend: a faint zig-zag path through four ink dots (ports the
/// prototype's inline SVG).
class _LegendPainter extends CustomPainter {
  const _LegendPainter();

  static const List<Offset> _points = [
    Offset(10, 30),
    Offset(34, 12),
    Offset(58, 28),
    Offset(72, 10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = CsTokens.faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..moveTo(_points.first.dx, _points.first.dy);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = CsTokens.fg;
    for (final p in _points) {
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(_LegendPainter oldDelegate) => false;
}
