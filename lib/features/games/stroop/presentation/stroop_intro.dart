import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_playing.dart';
import 'package:flutter/widgets.dart';

/// The Stroop intro: a legend showing the word/shape conflict (a square drawn
/// with the word "CIRCLE" on its plate), the rule, and a Begin button.
class StroopIntro extends StatelessWidget {
  /// Creates the intro.
  const StroopIntro({required this.round, required this.onStart, super.key});

  /// Trials this round (for the footnote).
  final int round;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Intro(
      text: 'Tap the shape you see — not the word written on it.',
      startLabel: 'Begin',
      footnote: '$round trials · tap the shape you see',
      onStart: onStart,
      // A square drawn with the word "CIRCLE" on its plate — the conflict.
      legend: const Stack(
        alignment: Alignment.center,
        children: [
          Shape(id: 1, size: 66, outline: true),
          StroopWordPlate('Circle', size: 10),
        ],
      ),
    );
  }
}
