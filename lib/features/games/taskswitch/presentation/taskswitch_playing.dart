import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:flutter/widgets.dart';

const double _bigSize = 150;
const double _smallSize = 92;

/// The Task Switching play surface: a rule banner that names the active rule,
/// the stimulus shape (its fill / size carrying the other two attributes),
/// bloom/shake feedback that keeps the stimulus visible, and two relabelling
/// option pills.
class TaskSwitchPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const TaskSwitchPlaying({
    required this.state,
    required this.onPick,
    super.key,
  });

  /// Current engine snapshot.
  final TaskSwitchState state;

  /// Option-tap handler (0 or 1).
  final void Function(int choice) onPick;

  @override
  Widget build(BuildContext context) {
    final stim = state.stim;
    if (stim == null) return const SizedBox.shrink();
    final labels = switchOptionLabels(state.rule);
    return Column(
      children: [
        const SizedBox(height: 20),
        _ruleBanner(state.rule),
        Expanded(child: Center(child: _stimulus(stim))),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: _option(i, labels[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ruleBanner(SwitchRule rule) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: const BoxDecoration(
          color: CsTokens.fg,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Label('Judge · ${rule.name}', color: CsTokens.bg),
      ),
    );
  }

  Widget _stimulus(SwitchStim stim) {
    final shape = Shape(
      id: stim.shape,
      size: stim.big ? _bigSize : _smallSize,
      outline: !stim.filled,
    );
    switch (state.fb) {
      case SwitchFeedback.hit:
        return Bloom(
          trigger: state.idx,
          duration: taskSwitchFeedback,
          child: shape,
        );
      case SwitchFeedback.wrong:
        return Shake(trigger: state.idx, playOnMount: true, child: shape);
      case null:
        return shape;
    }
  }

  Widget _option(int i, String label) {
    final picked = state.picked == i;
    return GestureDetector(
      key: ValueKey('switch-option-$i'),
      onTap: () => onPick(i),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: picked ? CsTokens.fg : CsTokens.line,
            width: 1.6,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: CsType.family,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            letterSpacing: 13.5 * 0.18,
            color: CsTokens.fg,
          ),
        ),
      ),
    );
  }
}
