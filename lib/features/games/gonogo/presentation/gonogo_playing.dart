import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/countdown.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_state.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:flutter/widgets.dart';

/// The Go/No-Go play surface: a response-window countdown, the stimulus (with
/// bloom / pulse / shake feedback that keeps it visible), and a tap hint.
/// Tapping anywhere is the Go response.
class GoNoGoPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const GoNoGoPlaying({required this.state, required this.onTap, super.key});

  /// Current engine snapshot.
  final GngState state;

  /// Tap handler (the Go response).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            height: 35,
            child: Center(
              child: state.showing && state.fb == null
                  ? Countdown(ms: gngDisplayMs, trialKey: state.idx)
                  : const SizedBox(width: 210, height: 3),
            ),
          ),
          Expanded(child: Center(child: _stimulus())),
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Label('Tap anywhere for the circle', color: CsTokens.faint),
          ),
        ],
      ),
    );
  }

  /// The stimulus stays visible for the whole feedback motion (DESIGN rule); it
  /// blanks only between trials (`showing == false && fb == null`).
  Widget _stimulus() {
    final shape = state.shape;
    if (shape == null || (!state.showing && state.fb == null)) {
      return const SizedBox.shrink();
    }
    switch (state.fb) {
      case GngFeedback.correctGo:
        return Bloom(
          trigger: state.idx,
          duration: gngFeedbackMotion,
          child: Shape(id: shape),
        );
      case GngFeedback.correctWithhold:
        return Pulse(
          trigger: state.idx,
          duration: gngFeedbackMotion,
          child: Shape(id: shape),
        );
      case GngFeedback.wrong:
        return Shake(
          trigger: state.idx,
          playOnMount: true,
          child: Shape(id: shape, outline: true),
        );
      case null:
        return Pop(
          trigger: state.idx,
          child: Shape(id: shape),
        );
    }
  }
}
