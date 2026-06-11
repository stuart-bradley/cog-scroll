import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:flutter/widgets.dart';

/// The Task Switching intro: a single-shape legend, the rule, and a Begin
/// button.
class TaskSwitchIntro extends StatelessWidget {
  /// Creates the intro.
  const TaskSwitchIntro({
    required this.round,
    required this.onStart,
    super.key,
  });

  /// Trials this round (for the footnote).
  final int round;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Intro(
      text:
          'The banner says what to judge — the shape, the fill, or the size. '
          'Watch for the switch.',
      startLabel: 'Begin',
      footnote: '$round trials · the rule keeps changing',
      onStart: onStart,
      legend: const Shape(id: 0, size: 42),
    );
  }
}
