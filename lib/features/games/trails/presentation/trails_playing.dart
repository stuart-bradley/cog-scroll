import 'dart:math';

import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/features/games/trails/domain/trails_board.dart';
import 'package:cogscroll/features/games/trails/domain/trails_engine.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:flutter/widgets.dart';

/// Minimum tappable square per dot (the ≥ ~44 px rule) — the L4–L5 "smaller
/// dots" lever shrinks the visual, never the hit area. Cell padding keeps dot
/// centres ≥ 50 px apart, so 44 px hit areas never overlap.
const double _minHit = 44;

/// The Trail Making play surface: the virtual board scaled to fit, an ink
/// polyline through the connected dots, and the labelled dots — filled once
/// done, shake-flashed (within the 360 ms window) on a wrong tap.
///
/// Takes only the board fields (not the full state) so the screen can keep it
/// off the per-tick `elapsed` rebuild path.
class TrailsPlaying extends StatelessWidget {
  /// Creates the play UI from the board fields.
  const TrailsPlaying({
    required this.level,
    required this.targets,
    required this.next,
    required this.bad,
    required this.onTapDot,
    super.key,
  });

  /// Difficulty level (drives the dot radius).
  final int level;

  /// The laid-out targets, in tap order.
  final List<TrailTarget> targets;

  /// Index of the next target to tap; targets below it are done.
  final int next;

  /// Index of a briefly shake-flashed wrong tap, or null.
  final int? bad;

  /// Dot-tap handler (sequence index).
  final void Function(int index) onTapDot;

  @override
  Widget build(BuildContext context) {
    final radius = trailRadiusForLevel(level);
    final hit = max(_minHit, radius * 2);
    return Center(
      child: FittedBox(
        child: SizedBox(
          width: trailBoardW,
          height: trailBoardH,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(trailBoardW, trailBoardH),
                painter: TrailPathPainter(
                  points: [
                    for (var i = 0; i < next; i++)
                      Offset(targets[i].x, targets[i].y),
                  ],
                ),
              ),
              for (var i = 0; i < targets.length; i++)
                Positioned(
                  left: targets[i].x - hit / 2,
                  top: targets[i].y - hit / 2,
                  child: _dot(i, radius: radius, hit: hit),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int i, {required double radius, required double hit}) {
    final target = targets[i];
    final done = i < next;
    final dot = GestureDetector(
      key: ValueKey('trail-dot-$i'),
      onTap: () => onTapDot(i),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: hit,
        height: hit,
        child: Center(
          child: Container(
            width: radius * 2,
            height: radius * 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? CsTokens.fg : CsTokens.bg,
              border: Border.all(color: CsTokens.fg, width: 2),
            ),
            child: Text(
              target.label,
              style: TextStyle(
                fontFamily: CsType.family,
                fontWeight: FontWeight.w600,
                fontSize: radius < 24 ? 14 : 17,
                height: 1,
                color: done ? CsTokens.bg : CsTokens.fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
    if (bad != i) return dot;
    // The flash window is 360ms, shorter than the default shake — run the
    // motion at the window so it completes while the dot is still flagged.
    return Shake(playOnMount: true, duration: trailsBadFlash, child: dot);
  }
}

/// Paints the ink polyline through the connected dot centres (ports the
/// prototype's `<polyline>`).
class TrailPathPainter extends CustomPainter {
  /// Creates a painter through [points] (the done dots, in order).
  const TrailPathPainter({required this.points});

  /// Centres of the connected dots.
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = CsTokens.fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrailPathPainter oldDelegate) =>
      oldDelegate.points.length != points.length;
}
