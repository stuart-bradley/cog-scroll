import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/ui_kit/progress.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:cogscroll/features/games/nback/domain/nback_state.dart';
import 'package:flutter/widgets.dart';

/// The N-Back play surface: the stimulus (with feedback motion), the progress
/// counter, and the Match button. Tapping anywhere or the button resolves.
class NbackPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const NbackPlaying({
    required this.state,
    required this.round,
    required this.onTap,
    super.key,
  });

  /// Current engine snapshot.
  final NbackState state;

  /// Trial count for the progress track.
  final int round;

  /// Match / tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fb = state.fb;
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: SizedBox(height: 240, child: Center(child: _stimulus(fb))),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 38),
          child: Progress(idx: state.idx + 1, total: round),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: WideButton(
            label: 'Match',
            onPressed: onTap,
            variant: fb == NbackFeedback.wrong
                ? WideButtonVariant.hollow
                : WideButtonVariant.solid,
            icon: switch (fb) {
              NbackFeedback.hit => WideButtonIcon.check,
              NbackFeedback.wrong => WideButtonIcon.cross,
              null => null,
            },
          ),
        ),
      ],
    );
  }

  /// The stimulus stays visible for the whole feedback motion (DESIGN rule);
  /// it blanks only between trials (showing == false && no feedback).
  Widget _stimulus(NbackFeedback? fb) {
    final shape = state.shape;
    if (shape == null || (!state.showing && fb == null)) {
      return const SizedBox.shrink();
    }
    switch (fb) {
      case NbackFeedback.hit:
        return Bloom(
          trigger: state.idx,
          child: Pop(
            variant: PopVariant.big,
            trigger: state.idx,
            child: Shape(id: shape),
          ),
        );
      case NbackFeedback.wrong:
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
