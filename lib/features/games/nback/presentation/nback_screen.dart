import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/nback/domain/nback_engine.dart';
import 'package:cogscroll/features/games/nback/domain/nback_state.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_controller.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_intro.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// N-Back (Working Memory). Standalone when [runner] is null; runner-driven in
/// baseline/session mode.
class NbackScreen extends ConsumerWidget {
  /// Creates the N-Back screen.
  const NbackScreen({this.runner, super.key});

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = nbackControllerProvider(runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final round = runner?.trials ?? nbackDefaultRound;

    final showLevel =
        state.phase == GamePhase.intro || state.phase == GamePhase.playing;

    return GameScaffold(
      phase: state.phase,
      title: 'N-Back',
      runner: runner,
      onBack: () => context.pop(),
      trailing: showLevel ? Label('${state.n}-Back', color: CsTokens.fg) : null,
      intro: NbackIntro(n: state.n, round: round, onStart: controller.start),
      playing: NbackPlaying(
        state: state,
        round: round,
        onTap: controller.tap,
      ),
      summary: state.summary == null ? null : _roundData(state, round),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(NbackState state, int round) {
    final summary = state.summary!;
    final accDelta = summary.accDelta;
    return (
      value: '${summary.acc}%',
      caption: 'Accuracy',
      sub: '${summary.playedN}-Back · $round trials',
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
