import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:flutter/widgets.dart';

/// The N-Back intro: a row of the six shapes, the rule, and a Begin button.
class NbackIntro extends StatelessWidget {
  /// Creates the intro for an [n]-back round of [round] trials.
  const NbackIntro({
    required this.n,
    required this.round,
    required this.onStart,
    super.key,
  });

  /// Current difficulty level N.
  final int n;

  /// Trial count for this round.
  final int round;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final steps = n == 1 ? 'step' : 'steps';
    return Intro(
      text: 'Tap Match when the shape is the same as the one $n $steps back.',
      startLabel: 'Begin',
      footnote: '$round trials',
      onStart: onStart,
      legend: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Shape(id: i, size: 26, color: CsTokens.sub),
            ),
        ],
      ),
    );
  }
}
