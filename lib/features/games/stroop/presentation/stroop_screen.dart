import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_controller.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_intro.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_playing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Stroop (Attention & Inhibition) — catalog-only (no runner). Tap the shape
/// you see, not the word written on it; the metric is interference cost.
class StroopScreen extends ConsumerWidget {
  /// Creates the Stroop screen.
  const StroopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stroopControllerProvider);
    final controller = ref.read(stroopControllerProvider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: 'Stroop',
      onBack: () => context.pop(),
      trailing: switch (state.phase) {
        GamePhase.intro => Label('Level ${state.level}', color: CsTokens.fg),
        GamePhase.playing => Label(
          '${state.idx + 1}/${state.round}',
          color: CsTokens.fg,
        ),
        GamePhase.round => null,
      },
      intro: StroopIntro(round: state.round, onStart: controller.start),
      playing: StroopPlaying(state: state, onPick: controller.pick),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(StroopState state) {
    final summary = state.summary!;
    // Interference is lower-is-better, so a negative delta is an improvement.
    final delta = summary.interferenceDelta;
    return (
      value: '${summary.interferenceMs}ms',
      caption: 'Interference',
      sub: 'Level ${summary.playedLevel} · ${state.round} trials',
      delta: delta == null || delta == 0
          ? null
          : (
              dir: delta < 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${delta.abs()}ms ${delta < 0 ? 'less' : 'more'} vs last',
            ),
      levelMsg: state.levelMsg,
    );
  }
}
