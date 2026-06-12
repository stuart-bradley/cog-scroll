import 'dart:math' as math;

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Radial inset from the box edge to the outermost ring, leaving room for the
/// domain labels that sit just outside it (`R = c - 46` in `cs-radar.jsx`).
const double _kRingInset = 46;

/// Gridline ring radii as a fraction of the full radius.
const List<double> _kRings = [0.25, 0.5, 0.75, 1];

/// Whether at least one domain has a measured score (the data polygon only
/// draws when true). Exposed for tests.
@visibleForTesting
bool radarHasData(Map<String, int?> scores) =>
    Domains.all.any((d) => scores[d] != null);

/// Whether the dashed baseline ghost polygon should be drawn: a ghost map must
/// be present, hold data, and differ from the current scores at some domain
/// measured in both. Mirrors `cs-radar.jsx`'s `ghostDiffers`. For tests.
@visibleForTesting
bool radarGhostVisible(Map<String, int?> scores, Map<String, int?>? ghost) {
  if (ghost == null) return false;
  final hasData = Domains.all.any((d) => ghost[d] != null);
  if (!hasData) return false;
  return Domains.all.any(
    (d) => ghost[d] != null && scores[d] != null && ghost[d] != scores[d],
  );
}

/// Six-spoke cognitive radar: a current-score polygon over concentric hexagon
/// gridlines, with an optional dashed baseline [ghost] and two-line spoke
/// labels. Pure black & white (DESIGN §7.2; ports `cs-radar.jsx`).
class Radar extends StatelessWidget {
  /// Creates a radar for [scores] (domain → 0–100 or null), optionally drawing
  /// a dashed [ghost] (baseline) polygon, sized [size]×[size].
  const Radar({required this.scores, this.ghost, this.size = 252, super.key});

  /// Current EMA score per domain; null where unmeasured.
  final Map<String, int?> scores;

  /// Baseline score per domain to draw as a dashed ghost; null disables it.
  final Map<String, int?>? ghost;

  /// Side length of the square the radar is painted into, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: RadarPainter(scores: scores, ghost: ghost),
    );
  }
}

/// Paints the [Radar]. Drawn in pixel space (no canvas scaling) because the
/// prototype parameterises all geometry by `size` and uses absolute stroke
/// widths, so scaling would distort them.
class RadarPainter extends CustomPainter {
  /// Creates a painter for [scores] with an optional baseline [ghost].
  const RadarPainter({required this.scores, this.ghost});

  /// Current EMA score per domain; null where unmeasured.
  final Map<String, int?> scores;

  /// Baseline score per domain to draw as a dashed ghost; null disables it.
  final Map<String, int?>? ghost;

  static const int _n = 6; // Domains.all.length

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - _kRingInset;

    _paintRings(canvas, center, r);
    _paintSpokes(canvas, center, r);
    if (radarGhostVisible(scores, ghost)) {
      _paintGhost(canvas, _vertsFor(ghost!, center, r));
    }
    if (radarHasData(scores)) {
      _paintData(canvas, _vertsFor(scores, center, r));
    }
    _paintVertices(canvas, center, r);
    _paintLabels(canvas, center, r);
  }

  /// Spoke angle in radians: starts at the top (−90°), clockwise.
  double _angle(int i) => (-90 + i * (360 / _n)) * math.pi / 180;

  Offset _pt(int i, double radius, Offset center) {
    final a = _angle(i);
    return Offset(
      center.dx + radius * math.cos(a),
      center.dy + radius * math.sin(a),
    );
  }

  double _radiusFor(int? v, double r) =>
      v == null ? r * 0.06 : r * (math.max(4, v) / 100);

  List<Offset> _vertsFor(Map<String, int?> src, Offset center, double r) => [
    for (var i = 0; i < _n; i++)
      _pt(i, _radiusFor(src[Domains.all[i]], r), center),
  ];

  Path _polygon(List<Offset> verts) {
    final path = Path()..moveTo(verts.first.dx, verts.first.dy);
    for (final v in verts.skip(1)) {
      path.lineTo(v.dx, v.dy);
    }
    return path..close();
  }

  void _paintRings(Canvas canvas, Offset center, double r) {
    for (var ri = 0; ri < _kRings.length; ri++) {
      final verts = [
        for (var i = 0; i < _n; i++) _pt(i, r * _kRings[ri], center),
      ];
      final paint = Paint()
        ..color = CsTokens.line
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..strokeWidth = ri == _kRings.length - 1 ? 1.4 : 1;
      canvas.drawPath(_polygon(verts), paint);
    }
  }

  void _paintSpokes(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = CsTokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;
    for (var i = 0; i < _n; i++) {
      canvas.drawLine(center, _pt(i, r, center), paint);
    }
  }

  void _paintGhost(Canvas canvas, List<Offset> verts) {
    final paint = Paint()
      ..color = CsTokens.faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    _drawDashed(canvas, _polygon(verts), paint);
  }

  void _paintData(Canvas canvas, List<Offset> verts) {
    final path = _polygon(verts);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = CsTokens.fg.withValues(alpha: 0.07)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      )
      ..drawPath(
        path,
        Paint()
          ..color = CsTokens.fg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
  }

  void _paintVertices(Canvas canvas, Offset center, double r) {
    for (var i = 0; i < _n; i++) {
      final v = scores[Domains.all[i]];
      final p = _pt(i, _radiusFor(v, r), center);
      if (v == null) {
        canvas
          ..drawCircle(
            p,
            3.5,
            Paint()
              ..color = CsTokens.bg
              ..isAntiAlias = true,
          )
          ..drawCircle(
            p,
            3.5,
            Paint()
              ..color = CsTokens.faint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..isAntiAlias = true,
          );
      } else {
        canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = CsTokens.fg
            ..isAntiAlias = true,
        );
      }
    }
  }

  void _paintLabels(Canvas canvas, Offset center, double r) {
    for (var i = 0; i < _n; i++) {
      final domain = Domains.all[i];
      final lines = kDomainShort[domain]!;
      final anchor = _pt(i, r + 22, center);
      final a = _angle(i);
      final cos = math.cos(a);
      final sin = math.sin(a);
      final color = scores[domain] != null ? CsTokens.sub : CsTokens.faint;
      final dy = sin < -0.3
          ? -6.0
          : sin > 0.3
          ? 16.0
          : 4.0;
      for (var li = 0; li < lines.length; li++) {
        final tp = TextPainter(
          text: TextSpan(
            text: lines[li],
            style: TextStyle(
              fontFamily: CsType.family,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 9 * 0.14,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // Emulate SVG textAnchor: start (left), end (right), or middle.
        final ox = cos > 0.3
            ? anchor.dx
            : cos < -0.3
            ? anchor.dx - tp.width
            : anchor.dx - tp.width / 2;
        // SVG `y` is the baseline; offset to the text box top for TextPainter.
        final baseline =
            anchor.dy +
            dy +
            li * 11 -
            tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        tp.paint(canvas, Offset(ox, baseline));
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const on = 3.0;
    const off = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + on;
        canvas.drawPath(
          metric.extractPath(dist, math.min(next, metric.length)),
          paint,
        );
        dist = next + off;
      }
    }
  }

  @override
  bool shouldRepaint(RadarPainter old) =>
      !mapEquals(old.scores, scores) || !mapEquals(old.ghost, ghost);
}
