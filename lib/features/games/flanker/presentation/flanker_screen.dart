import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_controller.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_intro.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Flanker (Sustained Attention). Standalone when [runner] is null;
/// runner-driven in baseline/session mode.
class FlankerScreen extends ConsumerWidget {
  /// Creates the Flanker screen.
  const FlankerScreen({this.runner, super.key});

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = flankerControllerProvider(runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Flanker',
      runner: runner,
      onBack: () => context.pop(),
      trailing: switch (state.phase) {
        GamePhase.intro => Label('Level ${state.level}', color: CsTokens.fg),
        GamePhase.playing => Label(
          '${state.idx + 1}/${state.round}',
          color: CsTokens.fg,
        ),
        GamePhase.round => null,
      },
      intro: FlankerIntro(round: state.round, onStart: controller.start),
      playing: FlankerPlaying(state: state, onRespond: controller.respond),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(FlankerState state) {
    final summary = state.summary!;
    final accDelta = summary.accDelta;
    return (
      value: '${summary.acc}%',
      caption: 'Accuracy',
      sub: 'Level ${summary.playedLevel} · ${state.round} trials',
      delta: accDelta == null
          ? null
          : (
              dir: accDelta >= 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${accDelta >= 0 ? '+' : ''}$accDelta% vs last round',
            ),
      levelMsg: state.levelMsg,
    );
  }
}
