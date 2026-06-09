import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_engine.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reaction_controller.g.dart';

/// Drives a [ReactionEngine] and republishes its snapshots as Riverpod state.
@riverpod
class ReactionController extends _$ReactionController {
  late final ReactionEngine _engine;

  @override
  ReactionState build(RunnerContext? runner) {
    _engine = ReactionEngine(
      sink: ref.watch(gameSinkProvider),
      store: ref.watch(gameStoreProvider),
      clock: ref.watch(clockProvider),
      runner: runner,
      timers: ref.watch(timersProvider),
    )..onChange = (snapshot) => state = snapshot;
    ref.onDispose(_engine.dispose);
    return _engine.state;
  }

  /// Begins a round (from the intro, or a new round after a standalone end).
  void start() => _engine.start();

  /// The player's tap.
  void tap() => _engine.tap();
}
