import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/countdown.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_trial.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_arrow.dart';
import 'package:flutter/widgets.dart';

const double _targetSize = 50;
const double _smallFlanker = 36;

/// The Flanker play surface: a response-window countdown, the five-arrow
/// stimulus (with directional-surge / shake feedback that keeps it visible),
/// left/right tap zones over the play area, and two arrow buttons.
class FlankerPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const FlankerPlaying({
    required this.state,
    required this.onRespond,
    super.key,
  });

  /// Current engine snapshot.
  final FlankerState state;

  /// Response handler — the side the middle arrow points.
  final void Function(FlankerDir side) onRespond;

  @override
  Widget build(BuildContext context) {
    final params = flankerParamsForLevel(state.level);
    return Column(
      children: [
        SizedBox(
          height: 35,
          child: Center(
            child: state.fb == null
                ? Countdown(ms: params.windowMs, trialKey: state.idx)
                : const SizedBox(width: 210, height: 3),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Center(child: _stimulus(params)),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onRespond(FlankerDir.left),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onRespond(FlankerDir.right),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: Row(
            children: [
              Expanded(
                child: _ArrowButton(dir: FlankerDir.left, onTap: onRespond),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ArrowButton(dir: FlankerDir.right, onTap: onRespond),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The five-arrow row. The stimulus stays visible for the whole feedback
  /// motion: a correct answer surges it toward the answer; a wrong answer (or a
  /// missed deadline) shakes it.
  Widget _stimulus(FlankerParams params) {
    final dir = state.dir;
    if (dir == null) return const SizedBox.shrink();
    final flankerDir = params.congruent ? dir : flipDir(dir);
    final flankerSize = params.fullSizeFlankers ? _targetSize : _smallFlanker;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < params.flankersPerSide; i++)
          _padded(FlankerArrow(dir: flankerDir, size: flankerSize)),
        _padded(FlankerArrow(dir: dir, size: _targetSize)),
        for (var i = 0; i < params.flankersPerSide; i++)
          _padded(FlankerArrow(dir: flankerDir, size: flankerSize)),
      ],
    );
    switch (state.fb) {
      case FlankerFeedback.hit:
        return Surge(
          trigger: state.idx,
          playOnMount: true,
          direction: dir == FlankerDir.right
              ? SurgeDirection.right
              : SurgeDirection.left,
          child: row,
        );
      case FlankerFeedback.wrong:
        return Shake(trigger: state.idx, playOnMount: true, child: row);
      case null:
        return row;
    }
  }

  Widget _padded(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: child);
}

/// A full-width arrow response button (a rounded outline pill).
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.dir, required this.onTap});

  final FlankerDir dir;
  final void Function(FlankerDir side) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(dir),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: CsTokens.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CsTokens.line, width: 1.6),
        ),
        child: Center(child: FlankerArrow(dir: dir, size: 32)),
      ),
    );
  }
}
