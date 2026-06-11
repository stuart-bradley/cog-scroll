import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:flutter/widgets.dart';

const double _stimSize = 232;
const double _optionSize = 64;

/// The Stroop play surface: a big outline shape with a conflicting word on a
/// white plate (tap the shape you *see*), bloom/shake feedback that keeps the
/// stimulus visible, and a row of shape options whose spacing tightens with
/// the level.
class StroopPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const StroopPlaying({required this.state, required this.onPick, super.key});

  /// Current engine snapshot.
  final StroopState state;

  /// Option-tap handler (shape id).
  final void Function(int shapeId) onPick;

  @override
  Widget build(BuildContext context) {
    final stim = state.stim;
    if (stim == null) return const SizedBox.shrink();
    // L1 wide (14) → L5 tight (6): the mono "spacing↓" difficulty lever.
    final gap = (14 - (state.level.clamp(1, 5) - 1) * 2).toDouble();
    return Column(
      children: [
        Expanded(child: Center(child: _stimulus(stim))),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 46),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final id in stim.options)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _option(id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stimulus(StroopStim stim) {
    final stack = Stack(
      alignment: Alignment.center,
      children: [
        Shape(id: stim.shape, size: _stimSize, outline: true),
        StroopWordPlate(kShapeNames[stim.word]),
      ],
    );
    switch (state.fb) {
      case StroopFeedback.hit:
        return Bloom(
          trigger: state.idx,
          size: _stimSize * 1.13,
          duration: stroopFeedback,
          child: stack,
        );
      case StroopFeedback.wrong:
        return Shake(trigger: state.idx, playOnMount: true, child: stack);
      case null:
        return stack;
    }
  }

  Widget _option(int id) {
    final picked = state.picked == id;
    return GestureDetector(
      key: ValueKey('stroop-option-$id'),
      onTap: () => onPick(id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _optionSize,
        height: _optionSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? CsTokens.fg : CsTokens.line,
            width: 1.6,
          ),
        ),
        child: Shape(id: id, size: 34),
      ),
    );
  }
}

/// The conflicting word drawn on a white plate so it stays legible over the
/// shape (ports the prototype's `<span>` plate). Shared by the intro legend.
class StroopWordPlate extends StatelessWidget {
  /// Creates a plate showing [word] at [size].
  const StroopWordPlate(this.word, {this.size = 17, super.key});

  /// The (upper-cased) shape name written on the plate.
  final String word;

  /// Font size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CsTokens.bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        word.toUpperCase(),
        style: TextStyle(
          fontFamily: CsType.family,
          fontWeight: FontWeight.w600,
          fontSize: size,
          letterSpacing: size * 0.04,
          color: CsTokens.fg,
        ),
      ),
    );
  }
}
