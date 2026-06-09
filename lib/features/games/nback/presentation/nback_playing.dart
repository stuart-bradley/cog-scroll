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
          child: _GhostBurst(shape: shape),
        );
      case null:
        return Pop(
          trigger: state.idx,
          child: Shape(id: shape),
        );
    }
  }
}

/// The wrong-answer burst: the outline stimulus (kept fully visible) with two
/// ghost copies that fade in then drift apart and out — ports the prototype's
/// `WrongBurst` (`csGhostA`/`csGhostB`). The shake itself is applied by the
/// caller wrapping this in a [Shake].
class _GhostBurst extends StatelessWidget {
  const _GhostBurst({required this.shape});

  final int shape;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) => Stack(
        alignment: Alignment.center,
        children: [
          _ghost(t, const Offset(-26, -13)),
          _ghost(t, const Offset(26, 13)),
          child!,
        ],
      ),
      child: Shape(id: shape, outline: true),
    );
  }

  Widget _ghost(double t, Offset end) {
    // Opacity 0 → 0.4 (at 35%) → 0, matching csGhostA/B.
    final opacity = t < 0.35 ? 0.4 * (t / 0.35) : 0.4 * (1 - (t - 0.35) / 0.65);
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: Offset.lerp(Offset.zero, end, t)!,
        child: Shape(id: shape, outline: true),
      ),
    );
  }
}
