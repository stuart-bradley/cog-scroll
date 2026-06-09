import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Default trial count for a full (non-runner) round.
const int reactionDefaultTrials = 5;

const int _minWaitMs = 1100;
const int _waitSpreadMs = 2600;
const Duration _gap = Duration(milliseconds: 1000);
const Duration _tooSoonPause = Duration(milliseconds: 950);

/// Pure reaction-time engine (Processing Speed). After a random delay a shape
/// appears; tap as fast as possible. A tap before the shape is "too soon" and
/// restarts the trial. No staircase — a baseline measure. Ports
/// `docs/design/cs-speed.jsx`; elapsed time is taken as `Clock.now()` deltas.
class ReactionEngine extends GameEngine<ReactionState> {
  /// Creates an engine. [trials] / [random] are injectable for tests.
  // Not super-params: the initializer reads the resolved total to seed.
  // ignore: use_super_parameters
  ReactionEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? trials,
    Random? random,
  }) : _total = trials ?? runner?.trials ?? reactionDefaultTrials,
       _random = random ?? Random(),
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(trials ?? runner?.trials ?? reactionDefaultTrials),
       );

  final int _total;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  ReactionStage _stage = ReactionStage.wait;
  int? _ms;
  int _trial = 0;
  ReactionSummary? _summary;

  final List<int> _times = [];
  DateTime? _readyAt;
  int? _lastAvg;

  static ReactionState _seed(int total) => (
    phase: GamePhase.intro,
    stage: ReactionStage.wait,
    ms: null,
    trial: 0,
    total: total,
    summary: null,
  );

  void _publish() => emit((
    phase: _phase,
    stage: _stage,
    ms: _ms,
    trial: _trial,
    total: _total,
    summary: _summary,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _lastAvg = store.getInt(CsStoreKeys.rtAvg);
    _times.clear();
    _trial = 0;
    _summary = null;
    _phase = GamePhase.playing;
    _publish();
    _next();
  }

  void _next() {
    clearTimers();
    _stage = ReactionStage.wait;
    _ms = null;
    _publish();
    final waitMs = _minWaitMs + (_random.nextDouble() * _waitSpreadMs).round();
    after(Duration(milliseconds: waitMs), () {
      _stage = ReactionStage.ready;
      _readyAt = clock.now();
      _publish();
    });
  }

  /// The player's tap.
  void tap() {
    if (_phase != GamePhase.playing) return;
    switch (_stage) {
      case ReactionStage.wait:
        clearTimers();
        _stage = ReactionStage.tooSoon;
        _publish();
        after(_tooSoonPause, _next);
      case ReactionStage.ready:
        clearTimers();
        final readyAt = _readyAt;
        final ms = readyAt == null
            ? 0
            : clock.now().difference(readyAt).inMilliseconds;
        _times.add(ms);
        _ms = ms;
        _stage = ReactionStage.result;
        _trial += 1;
        _publish();
        after(_gap, () {
          if (_trial >= _total) {
            _finish();
          } else {
            _next();
          }
        });
      case ReactionStage.result:
      case ReactionStage.tooSoon:
        break; // ignore taps while showing a result or the too-soon shake
    }
  }

  void _finish() {
    clearTimers();
    final avg = jsRound(_times.reduce((a, b) => a + b) / _times.length);
    final best = _times.reduce((a, b) => a < b ? a : b);
    final previous = _lastAvg;
    store.setInt(CsStoreKeys.rtAvg, avg);
    final norm = normalize('rt-avg', avg);
    unawaited(sink.recordResult(Domains.processingSpeed, norm));

    _phase = GamePhase.round;
    _stage = ReactionStage.wait;
    _ms = null;

    final activeRunner = runner;
    if (activeRunner != null) {
      _publish();
      activeRunner.onDone(norm);
      return;
    }
    _summary = (avg: avg, best: best, previous: previous);
    _publish();
  }
}
