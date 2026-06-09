import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:flutter/widgets.dart';

/// The Go/No-Go intro: a Tap (circle) / Hold (square) legend, the rule, and a
/// Begin button.
class GoNoGoIntro extends StatelessWidget {
  /// Creates the intro for a round of [round] trials.
  const GoNoGoIntro({required this.round, required this.onStart, super.key});

  /// Trial count for this round.
  final int round;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Intro(
      text: 'Tap for the circle. Hold still for the square.',
      startLabel: 'Begin',
      footnote: '$round trials',
      onStart: onStart,
      legend: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(shape: gngGoShape, caption: 'Tap'),
          SizedBox(width: 26),
          _LegendItem(
            shape: gngNoGoSquare,
            caption: 'Hold',
            color: CsTokens.sub,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.shape,
    required this.caption,
    this.color = CsTokens.fg,
  });

  final int shape;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Shape(id: shape, size: 42, color: color),
        const SizedBox(height: 8),
        Label(caption, size: 10),
      ],
    );
  }
}
