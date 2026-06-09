import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:flutter/widgets.dart';

/// The Reaction Time intro: a single shape, the rule, and a Begin button.
class ReactionIntro extends StatelessWidget {
  /// Creates the intro for a [total]-tap round.
  const ReactionIntro({required this.total, required this.onStart, super.key});

  /// Trial count for this round.
  final int total;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Intro(
      text:
          'When the shape appears, tap as fast as you can. '
          "Don't jump the gun.",
      startLabel: 'Begin',
      footnote: '$total taps',
      onStart: onStart,
      legend: const Shape(id: 0, size: 40, color: CsTokens.sub),
    );
  }
}
