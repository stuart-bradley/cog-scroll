import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:flutter/widgets.dart';

/// A domain's recent-vs-earlier [DomainTrend] as a glyph + word: an up/down
/// triangle for improving/declining, a flat rule for stable, and a plain
/// "Not enough data yet" caption under three results (ports `TrendMark`).
class TrendMark extends StatelessWidget {
  /// Creates a trend mark for [trend].
  const TrendMark({required this.trend, super.key});

  /// The trend to render.
  final DomainTrend trend;

  @override
  Widget build(BuildContext context) {
    if (trend.state == TrendState.none) {
      return const Text(
        'Not enough data yet',
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 11 * 0.02,
          color: CsTokens.faint,
        ),
      );
    }

    final up = trend.state == TrendState.improving;
    final down = trend.state == TrendState.declining;
    final word = up
        ? 'Improving'
        : down
        ? 'Declining'
        : 'Stable';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (up || down)
          CustomPaint(
            key: ValueKey(trend.state),
            size: const Size.square(9),
            painter: _TriangleMarker(up: up),
          )
        else
          Container(
            key: const ValueKey(TrendState.stable),
            width: 9,
            height: 2,
            color: CsTokens.faint,
          ),
        const SizedBox(width: 6),
        Label(word, size: 10.5, color: up || down ? CsTokens.fg : CsTokens.sub),
      ],
    );
  }
}

/// A 9×9 up/down triangle (same glyph paths as the RoundEnd delta marker).
class _TriangleMarker extends CustomPainter {
  const _TriangleMarker({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 11);
    final paint = Paint()
      ..color = CsTokens.fg
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
  bool shouldRepaint(_TriangleMarker old) => old.up != up;
}
