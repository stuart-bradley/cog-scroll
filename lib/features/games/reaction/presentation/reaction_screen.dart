import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_controller.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_intro.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reaction Time (Processing Speed). Standalone when [runner] is null;
/// runner-driven in baseline/session mode.
class ReactionScreen extends ConsumerWidget {
  /// Creates the Reaction Time screen.
  const ReactionScreen({this.runner, super.key});

  /// The runner context, or null for a standalone launch.
  final RunnerContext? runner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reactionControllerProvider(runner);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Reaction Time',
      runner: runner,
      onBack: () => context.pop(),
      trailing: state.phase == GamePhase.playing
          ? Label('${state.trial + 1}/${state.total}', color: CsTokens.fg)
          : null,
      intro: ReactionIntro(total: state.total, onStart: controller.start),
      playing: ReactionPlaying(state: state, onTap: controller.tap),
      summary: state.summary == null ? null : _roundData(state),
      continueLabel: 'Again',
      onContinue: controller.start,
    );
  }

  RoundData _roundData(ReactionState state) {
    final summary = state.summary!;
    final previous = summary.previous;
    return (
      value: '${summary.avg}',
      caption: 'Avg · ms',
      sub: 'Best ${summary.best} ms',
      delta: previous == null
          ? null
          : summary.avg <= previous
          ? (dir: DeltaDirection.up, text: '${previous - summary.avg}ms faster')
          : (
              dir: DeltaDirection.down,
              text: '${summary.avg - previous}ms slower',
            ),
      levelMsg: null,
    );
  }
}
