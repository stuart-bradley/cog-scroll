import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_complete.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_controller.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_welcome.dart';
import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The first-run baseline runner: welcome → six abbreviated games → seeded
/// radar reveal → Home. Ports the prototype's `Baseline` (`cs-onboarding.jsx`).
///
/// The flow state lives in [BaselineController]; this widget owns navigation
/// (Exit / Done → `/`) and mounts the current game.
class BaselineRunnerScreen extends ConsumerWidget {
  /// Creates the baseline runner screen.
  const BaselineRunnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(baselineControllerProvider);
    final controller = ref.read(baselineControllerProvider.notifier);
    void exit() => context.go('/');

    switch (state.stage) {
      case BaselineStage.welcome:
        return Scaffold(
          backgroundColor: CsTokens.bg,
          body: SafeArea(
            child: BaselineWelcome(onStart: controller.start, onExit: exit),
          ),
        );
      case BaselineStage.playing:
        // ValueKey(step) forces a clean remount (fresh engine) per game.
        return _BaselineGameStep(
          key: ValueKey(state.step),
          step: state.step,
          onAdvance: controller.advance,
          onExit: exit,
        );
      case BaselineStage.done:
        return Scaffold(
          backgroundColor: CsTokens.bg,
          body: SafeArea(child: BaselineComplete(onDone: exit)),
        );
    }
  }
}

/// Mounts the game for [step], building its [RunnerContext] **once** in
/// `initState`.
///
/// This is load-bearing: `RunnerContext` has identity equality and the game
/// controllers are autoDispose families keyed on it, so rebuilding the context
/// inside `build` would mint a new key on every incidental rebuild and silently
/// dispose+recreate the engine mid-game. Caching it here (plus the parent's
/// `ValueKey(step)`) gives exactly one engine per game.
class _BaselineGameStep extends StatefulWidget {
  const _BaselineGameStep({
    required this.step,
    required this.onAdvance,
    required this.onExit,
    super.key,
  });

  final int step;
  final VoidCallback onAdvance;
  final VoidCallback onExit;

  @override
  State<_BaselineGameStep> createState() => _BaselineGameStepState();
}

class _BaselineGameStepState extends State<_BaselineGameStep> {
  late final GameDescriptor _game;
  late final RunnerContext _runner;

  @override
  void initState() {
    super.initState();
    final step = baselineSet[widget.step];
    // Non-null: baseline_set_test asserts every id resolves in the registry.
    _game = GameRegistry.byId(step.id)!;
    _runner = RunnerContext(
      index: widget.step,
      total: baselineSet.length,
      domain: _game.domain,
      focus: false,
      headerLabel: 'Baseline',
      trials: step.trials,
      points: step.points,
      // Both finishing and skipping advance; a skipped game records nothing.
      onDone: (_) => widget.onAdvance(),
      onSkip: widget.onAdvance,
      onExit: widget.onExit,
    );
  }

  @override
  Widget build(BuildContext context) => _game.build(runner: _runner);
}
