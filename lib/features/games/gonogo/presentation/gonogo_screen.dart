import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/gonogo/domain/gonogo_state.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_controller.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_intro.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Go/No-Go (Attention & Inhibition). Standalone when [runner] is null;
/// runner-driven in baseline/session mode.
class GoNoGoScreen extends ConsumerWidget {
  /// Creates the Go/No-Go screen.
  const GoNoGoScreen({this.runner, super.key});

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = goNoGoControllerProvider(runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Go / No-Go',
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
      intro: GoNoGoIntro(round: state.round, onStart: controller.start),
      playing: GoNoGoPlaying(state: state, onTap: controller.tap),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(GngState state) {
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
