import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_engine.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flanker_controller.g.dart';

/// Drives a [FlankerEngine] and republishes its snapshots as Riverpod state.
///
/// AutoDispose: when the screen leaves the tree the engine's timers are
/// cancelled via `ref.onDispose`. The [runner] family arg is null for a
/// standalone launch, or the runner's context in baseline/session mode.
@riverpod
class FlankerController extends _$FlankerController {
  late final FlankerEngine _engine;

  @override
  FlankerState build(RunnerContext? runner) {
    _engine = FlankerEngine(
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

  /// The player's response: the side the middle arrow points.
  void respond(FlankerDir side) => _engine.respond(side);
}
