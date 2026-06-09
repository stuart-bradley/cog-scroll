import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:flutter/widgets.dart';

/// The Corsi intro: a small lit-cell grid legend, the rule, and a Begin button.
class CorsiIntro extends StatelessWidget {
  /// Creates the intro for a round of [trials] trials.
  const CorsiIntro({required this.trials, required this.onStart, super.key});

  /// Trial count for this round.
  final int trials;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    // A 3×3 sketch with three lit cells, matching the prototype legend.
    const lit = [false, true, false, false, false, true, true, false, false];
    return Intro(
      text:
          'The squares light up in order. '
          'Tap them back in the same sequence.',
      startLabel: 'Begin',
      footnote: 'Watch, then repeat',
      onStart: onStart,
      legend: SizedBox(
        width: 49,
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final on in lit)
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: on ? CsTokens.fg : CsTokens.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
