import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_controller.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_intro.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Spatial Grid / Corsi (Spatial Reasoning). Standalone when [runner] is null;
/// runner-driven in baseline/session mode.
class CorsiScreen extends ConsumerWidget {
  /// Creates the Corsi screen.
  const CorsiScreen({this.runner, super.key});

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = corsiControllerProvider(runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Spatial Grid',
      runner: runner,
      onBack: () => context.pop(),
      trailing: state.phase == GamePhase.playing
          ? Label('${state.trial + 1}/${state.trials}', color: CsTokens.fg)
          : null,
      intro: CorsiIntro(trials: state.trials, onStart: controller.start),
      playing: CorsiPlaying(state: state, onTapCell: controller.tapCell),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(CorsiState state) {
    final summary = state.summary!;
    final spanDelta = summary.spanDelta;
    return (
      value: '${summary.span}',
      caption: 'Best span',
      sub: 'Cells recalled',
      delta: spanDelta == null || spanDelta == 0
          ? null
          : (
              dir: spanDelta > 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${spanDelta > 0 ? '+' : ''}$spanDelta vs last',
            ),
      levelMsg: null,
    );
  }
}
