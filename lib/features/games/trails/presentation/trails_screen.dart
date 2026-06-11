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
    final controller = ref.read(provider.notifier);
    // Watch everything *except* elapsed: the 100ms tick changes only elapsed,
    // which the `_ElapsedReadout` consumer below watches in isolation — so the
    // board (up to 25 dots) rebuilds only on a tap, not 10x/second.
    final view = ref.watch(
      provider.select(
        (s) => (
          phase: s.phase,
          level: s.level,
          count: s.count,
          targets: s.targets,
          next: s.next,
          bad: s.bad,
          summary: s.summary,
          levelMsg: s.levelMsg,
        ),
      ),
    );

    return GameScaffold(
      phase: view.phase,
      title: mode == TrailMode.b ? 'Trail Making · Letters' : 'Trail Making',
      runner: runner,
      onBack: () => context.pop(),
      trailing: switch (view.phase) {
        GamePhase.intro => Label('Level ${view.level}', color: CsTokens.fg),
        GamePhase.playing => _ElapsedReadout(mode: mode, runner: runner),
        GamePhase.round => null,
      },
      intro: TrailsIntro(
        mode: mode,
        count: view.count,
        onStart: controller.start,
      ),
      playing: TrailsPlaying(
        level: view.level,
        targets: view.targets,
        next: view.next,
        bad: view.bad,
        onTapDot: controller.tap,
      ),
      summary: view.summary == null
          ? null
          : _roundData(view.summary!, view.levelMsg),
      continueLabel: 'Again',
      onContinue: controller.start,
    );
  }

  RoundData _roundData(TrailsSummary summary, String? levelMsg) {
    // Pace (s/target), not raw seconds, so the delta stays comparable when a
    // level change alters the count. Sub-0.05 deltas format as "0.0" —
    // suppress them like the span games (the PR4 zero-delta preference).
    final delta = summary.paceDelta;
    final deltaText = delta?.abs().toStringAsFixed(1);
    return (
      value: summary.seconds.toStringAsFixed(1),
      caption: 'Seconds',
      sub: 'Level ${summary.playedLevel} · ${summary.count} targets',
      delta: delta == null || deltaText == '0.0'
          ? null
          : (
              dir: delta < 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${deltaText}s/target ${delta < 0 ? 'faster' : 'slower'}',
            ),
      levelMsg: levelMsg,
    );
  }
}

/// The standalone TopBar elapsed-time readout. Its own consumer watching only
/// `elapsed`, so the 100ms tick rebuilds this Label alone — not the board.
class _ElapsedReadout extends ConsumerWidget {
  const _ElapsedReadout({required this.mode, required this.runner});

  final TrailMode mode;
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(
      trailsControllerProvider(mode, runner).select((s) => s.elapsed),
    );
    return Label('${elapsed.toStringAsFixed(1)}s', color: CsTokens.fg);
  }
}
