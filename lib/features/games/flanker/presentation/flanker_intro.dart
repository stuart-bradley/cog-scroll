import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_arrow.dart';
import 'package:flutter/widgets.dart';

/// The Flanker intro: a five-arrow legend with the middle arrow emphasised, the
/// rule, and a Begin button.
class FlankerIntro extends StatelessWidget {
  /// Creates the intro for a round of [round] trials.
  const FlankerIntro({required this.round, required this.onStart, super.key});

  /// Trial count for this round.
  final int round;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    // L L R L L — the middle (target) points the other way; emphasise it.
    const dirs = [
      FlankerDir.left,
      FlankerDir.left,
      FlankerDir.right,
      FlankerDir.left,
      FlankerDir.left,
    ];
    return Intro(
      text: 'Tap the side the middle arrow points — ignore the others.',
      startLabel: 'Begin',
      footnote: '$round trials',
      onStart: onStart,
      legend: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dirs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FlankerArrow(
                dir: dirs[i],
                size: 28,
                color: i == 2 ? CsTokens.fg : CsTokens.faint,
              ),
            ),
        ],
      ),
    );
  }
}
