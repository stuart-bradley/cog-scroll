import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';

/// In-memory [GameStore] for engine unit tests.
class FakeGameStore implements GameStore {
  /// The backing map (inspect it to assert persisted state).
  final Map<String, Object> values = {};

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  double? getDouble(String key) => (values[key] as num?)?.toDouble();

  @override
  String? getString(String key) => values[key] as String?;

  @override
  void setInt(String key, int value) => values[key] = value;

  @override
  void setDouble(String key, double value) => values[key] = value;

  @override
  void setString(String key, String value) => values[key] = value;
}

/// [GameSink] that records every `recordResult` call for assertions.
class FakeGameSink implements GameSink {
  /// The recorded calls, in order.
  final List<({String domain, int score})> calls = [];

  @override
  Future<void> recordResult(String domain, int score) async {
    calls.add((domain: domain, score: score));
  }
}

/// Builds a [RunnerContext] and captures its callbacks for runner-mode tests.
class FakeRunnerContext {
  /// Creates a fake runner context with optional abbreviated lengths.
  FakeRunnerContext({this.trials, this.points});

  /// Abbreviated trial count passed through to the [context].
  final int? trials;

  /// Abbreviated target count passed through to the [context].
  final int? points;

  /// The score the game passed to `onDone`, or null if not yet finished.
  int? doneScore;

  /// How many times `onDone` fired.
  int doneCount = 0;

  /// Whether `onSkip` fired.
  bool skipped = false;

  /// The context to hand to the game under test.
  late final RunnerContext context = RunnerContext(
    index: 0,
    total: 1,
    domain: 'Working Memory',
    focus: false,
    trials: trials,
    points: points,
    onDone: (score) {
      doneScore = score;
      doneCount++;
    },
    onSkip: () => skipped = true,
  );
}
