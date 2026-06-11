import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'taskswitch_controller.g.dart';

/// Drives a [TaskSwitchEngine] and republishes its snapshots as Riverpod state.
///
/// Catalog-only: never family-keyed by a runner — Task Switching is not
/// runner-capable (`SPEC.md` §7). AutoDispose cancels the engine's timers via
/// `ref.onDispose` when the screen leaves.
@riverpod
class TaskSwitchController extends _$TaskSwitchController {
  late final TaskSwitchEngine _engine;

  @override
  TaskSwitchState build() {
    _engine = TaskSwitchEngine(
      sink: ref.watch(gameSinkProvider),
      store: ref.watch(gameStoreProvider),
      clock: ref.watch(clockProvider),
      timers: ref.watch(timersProvider),
    )..onChange = (snapshot) => state = snapshot;
    ref.onDispose(_engine.dispose);
    return _engine.state;
  }

  /// Begins a round (from the intro, or a new round after a standalone end).
  void start() => _engine.start();

  /// Taps option [choice] (0 or 1) for the active rule.
  void pick(int choice) => _engine.pick(choice);
}
