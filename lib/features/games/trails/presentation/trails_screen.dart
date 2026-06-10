import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_controller.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_intro.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_playing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Trail Making (Mental Flexibility). [mode] selects A (numbers 1→N) or B
/// (number/letter alternation); each is a separate `GameRegistry` entry backed
/// by this one screen. Standalone when [runner] is null; runner-driven in
/// baseline/session mode.
class TrailsScreen extends ConsumerWidget {
  /// Creates the Trail Making screen for [mode].
  const TrailsScreen({required this.mode, this.runner, super.key});

  /// Mode A (numbers) or Mode B (number/letter alternation).
  final TrailMode mode;

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = trailsControllerProvider(mode, runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: mode == TrailMode.b ? 'Trails · Letters' : 'Trail Making',
      runner: runner,
      onBack: () => context.pop(),
      trailing: switch (state.phase) {
        GamePhase.intro => Label('Level ${state.level}', color: CsTokens.fg),
        GamePhase.playing => Label(
          '${state.elapsed.toStringAsFixed(1)}s',
          color: CsTokens.fg,
        ),
        GamePhase.round => null,
      },
      intro: TrailsIntro(
        mode: mode,
        count: state.count,
        onStart: controller.start,
      ),
      playing: TrailsPlaying(state: state, onTapDot: controller.tap),
      summary: state.summary == null ? null : _roundData(state),
      continueLabel: 'Again',
      onContinue: controller.start,
    );
  }

  RoundData _roundData(TrailsState state) {
    final summary = state.summary!;
    final delta = summary.secondsDelta;
    // Sub-0.05s deltas format as "0.0s" — suppress them like the span games.
    final deltaText = delta?.abs().toStringAsFixed(1);
    return (
      value: summary.seconds.toStringAsFixed(1),
      caption: 'Seconds',
      sub: 'Level ${summary.playedLevel} · ${summary.count} targets',
      delta: delta == null || deltaText == '0.0'
          ? null
          : (
              dir: delta < 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${deltaText}s ${delta < 0 ? 'faster' : 'slower'}',
            ),
      levelMsg: state.levelMsg,
    );
  }
}
