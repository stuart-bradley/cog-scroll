import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/entrance_fade.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:flutter/widgets.dart';

/// The Reaction Time play surface. Tap anywhere; the rendering depends on the
/// trial [ReactionStage]: blank wait, the stimulus, the measured time, or the
/// too-soon shake.
class ReactionPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const ReactionPlaying({required this.state, required this.onTap, super.key});

  /// Current engine snapshot.
  final ReactionState state;

  /// Tap handler.
  final VoidCallback onTap;

  static const _msStyle = TextStyle(
    fontFamily: CsType.family,
    fontWeight: FontWeight.w600,
    fontSize: 64,
    letterSpacing: -1.3,
    color: CsTokens.fg,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(child: _body()),
    );
  }

  Widget _body() {
    switch (state.stage) {
      case ReactionStage.wait:
        return const Label('Wait for it…', color: CsTokens.faint, size: 14);
      case ReactionStage.ready:
        return const Pop(child: Shape(id: 0, size: 200));
      case ReactionStage.result:
        return EntranceFade(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${state.ms}', style: _msStyle),
              const SizedBox(height: 14),
              const Label('ms'),
            ],
          ),
        );
      case ReactionStage.tooSoon:
        return const Shake(
          playOnMount: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Shape(id: 0, size: 200, outline: true),
              SizedBox(height: 14),
              Label('Too soon', color: CsTokens.fg),
            ],
          ),
        );
    }
  }
}
