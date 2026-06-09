import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_sequence.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Default trial count for a full (non-runner) round.
const int corsiDefaultTrials = 6;

/// Cold-start span (first ever play); thereafter the engine resumes from the
/// persisted best so the player operates near their limit (`SPEC.md` §7).
const int corsiStartSpan = 3;

/// Floor the within-play staircase never drops below.
const int corsiMinSpan = 2;

const Duration _showStart = Duration(milliseconds: 400);
const Duration _litFor = Duration(milliseconds: 480);
const Duration _cellGap = Duration(milliseconds: 640);
const Duration _tapLit = Duration(milliseconds: 180);
const Duration _hitFeedback = Duration(milliseconds: 850);
const Duration _wrongFeedback = Duration(milliseconds: 1000);

/// Pure Corsi / spatial-grid engine (Spatial Reasoning). Cells flash in order;
/// tap them back in the same sequence. A within-play ±1 span staircase resumes
/// from the persisted best (cold start 3, floor 2); the grid grows 4×4 → 5×5
/// once the span exceeds 6. Ports `docs/design/cs-memory.jsx`, with the grid
/// growth restored per `SPEC.md` §7.1.
class CorsiEngine extends GameEngine<CorsiState> {
  /// Creates an engine. [trials] / [random] are injectable for tests; otherwise
  /// the trial count comes from the runner (abbreviated) or the full default.
  // Not super-params: the initializer resolves the trial count to seed.
  // ignore: use_super_parameters
  CorsiEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? trials,
    Random? random,
  }) : _trials = trials ?? runner?.trials ?? corsiDefaultTrials,
       _random = random ?? Random(),
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(trials ?? runner?.trials ?? corsiDefaultTrials),
       );

  final int _trials;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  CorsiStage _stage = CorsiStage.show;
  int _gridN = 4;
  int _trial = 0;
  int _lit = -1;
  int _bad = -1;
  List<int> _taps = const [];
  CorsiFeedback? _fb;
  CorsiSummary? _summary;

  bool _resolved = false;
  int _pos = 0;
  List<int> _seq = const [];
  late SpanStaircase _staircase;
  int? _lastBest;

  static CorsiState _seed(int trials) => (
    phase: GamePhase.intro,
    stage: CorsiStage.show,
    gridN: 4,
    level: corsiStartSpan,
    trial: 0,
    trials: trials,
    lit: -1,
    taps: const [],
    bad: -1,
    fb: null,
    summary: null,
  );

  void _publish() => emit((
    phase: _phase,
    stage: _stage,
    gridN: _gridN,
    level: _staircase.level,
    trial: _trial,
    trials: _trials,
    lit: _lit,
    taps: _taps,
    bad: _bad,
    fb: _fb,
    summary: _summary,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    final persistedBest = store.getInt(CsStoreKeys.corsiSpan);
    final startLevel = persistedBest == null
        ? corsiStartSpan
        : max(corsiMinSpan, persistedBest);
    _staircase = SpanStaircase(level: startLevel, minSpan: corsiMinSpan);
    _lastBest = persistedBest;
    _trial = 0;
    _summary = null;
    _phase = GamePhase.playing;
    _present();
  }

  void _present() {
    clearTimers();
    _resolved = false;
    _pos = 0;
    _gridN = corsiGridSize(max(_staircase.level, _staircase.best));
    _seq = buildCorsiSequence(_gridN, _staircase.level, _random);
    _stage = CorsiStage.show;
    _taps = const [];
    _fb = null;
    _lit = -1;
    _bad = -1;
    _publish();
    var t = _showStart;
    for (final cell in _seq) {
      after(t, () {
        _lit = cell;
        _publish();
      });
      after(t + _litFor, () {
        _lit = -1;
        _publish();
      });
      t += _cellGap;
    }
    after(t, () {
      _stage = CorsiStage.recall;
      _publish();
    });
  }

  /// Taps cell [c] during recall.
  void tapCell(int c) {
    if (_resolved || _stage != CorsiStage.recall) return;
    if (c == _seq[_pos]) {
      _pos += 1;
      _taps = [..._taps, c];
      _lit = c;
      _publish();
      after(_tapLit, () {
        _lit = -1;
        _publish();
      });
      if (_pos >= _staircase.level) _judge(correct: true, bad: -1);
    } else {
      _judge(correct: false, bad: c);
    }
  }

  void _judge({required bool correct, required int bad}) {
    _resolved = true;
    clearTimers();
    _staircase.recordTrial(correct: correct);
    _fb = correct ? CorsiFeedback.hit : CorsiFeedback.wrong;
    _bad = bad;
    _publish(); // grid stays visible through the feedback motion
    _trial += 1;
    after(correct ? _hitFeedback : _wrongFeedback, _advance);
  }

  void _advance() {
    clearTimers();
    if (_trial >= _trials) {
      _finish();
    } else {
      _present();
    }
  }

  void _finish() {
    clearTimers();
    final best = _staircase.best;
    store.setInt(CsStoreKeys.corsiSpan, best);
    final norm = normalize('corsi-span', best);
    unawaited(sink.recordResult(Domains.spatialReasoning, norm));

    _phase = GamePhase.round;
    _stage = CorsiStage.show;
    _lit = -1;
    _bad = -1;
    _taps = const [];
    _fb = null;
    final lastBest = _lastBest;
    final spanDelta = lastBest == null ? null : best - lastBest;

    final activeRunner = runner;
    if (activeRunner != null) {
      _publish();
      activeRunner.onDone(norm);
      return;
    }
    _summary = (span: best, spanDelta: spanDelta);
    _publish();
  }
}
