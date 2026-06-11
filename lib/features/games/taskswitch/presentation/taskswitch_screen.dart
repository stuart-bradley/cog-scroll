import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_controller.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_intro.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_playing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Task Switching (Mental Flexibility) — catalog-only (no runner). Judge the
/// active rule (shape / fill / size); the rule keeps switching.
class TaskSwitchScreen extends ConsumerWidget {
  /// Creates the Task Switching screen.
  const TaskSwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskSwitchControllerProvider);
    final controller = ref.read(taskSwitchControllerProvider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Task Switching',
      onBack: () => context.pop(),
      trailing: switch (state.phase) {
        GamePhase.intro => Label('Level ${state.level}', color: CsTokens.fg),
        GamePhase.playing => Label(
          '${state.idx + 1}/${state.round}',
          color: CsTokens.fg,
        ),
        GamePhase.round => null,
      },
      intro: TaskSwitchIntro(round: state.round, onStart: controller.start),
      playing: TaskSwitchPlaying(state: state, onPick: controller.pick),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(TaskSwitchState state) {
    final summary = state.summary!;
    final accDelta = summary.accDelta;
    return (
      value: '${summary.acc}%',
      caption: 'Accuracy',
      sub: 'Level ${summary.playedLevel} · ${state.round} trials',
      delta: accDelta == null || accDelta == 0
          ? null
          : (
              dir: accDelta > 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${accDelta > 0 ? '+' : ''}$accDelta% vs last round',
            ),
      levelMsg: state.levelMsg,
    );
  }
}
