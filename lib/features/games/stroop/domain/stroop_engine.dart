import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_trial.dart';

/// Trial count for a Stroop round (catalog-only — no runner).
const int stroopTrials = 18;

/// Post-resolve feedback window (the prototype's 640 ms). The correct-tap
/// Bloom is given this as its `duration` so it completes with the stimulus
/// visible (DESIGN non-negotiable); the wrong Shake (500 ms) already fits.
const Duration stroopFeedback = Duration(milliseconds: 640);

/// Staircase thresholds on interference cost (ms, lower is better): up below
/// the "good" interference band, down above the mid band (anchored to the
/// §4.3 norm table — good Stroop interference < 80 ms).
const int stroopUpThreshold = 90;

/// See [stroopUpThreshold].
const int stroopDownThreshold = 180;

/// Pure shape-Stroop engine (Attention & Inhibition) — **catalog-only** (no
/// runner). A word naming one shape is drawn over a *different* shape; tap the
/// shape you see. The metric is **interference cost** (mean incongruent RT −
/// mean congruent RT, ms; lower is better), captured via `Clock.now()` deltas.
/// A two-consecutive-rounds ±1 staircase rides a difficulty level (1–5; faster
/// presentation / confusable shapes / more options) on interference. Ports
/// `docs/design/cs-attention.jsx`, with the interference metric and difficulty
/// system restored per `SPEC.md` §7.
class StroopEngine extends GameEngine<StroopState> {
  /// Creates an engine. [round] / [random] are injectable for tests.
  // Not super-params: the initializer reads `store` to seed the snapshot.
  // ignore: use_super_parameters
  StroopEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    Timers timers = const RealTimers(),
    int? round,
    Random? random,
  }) : _round = round ?? stroopTrials,
       _random = random ?? Random(),
       _level = store.getInt(CsStoreKeys.stroopLevel) ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         timers: timers,
         initial: _seed(store, round ?? stroopTrials),
       );

  final int _round;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _level;
  int _idx = 0;
  StroopStim? _stim;
  int? _picked;
  StroopFeedback? _fb;
  StroopSummary? _summary;
  String? _levelMsg;

  bool _resolved = false;
  late LevelStaircase _staircase;
  late DateTime _shownAt;
  int? _lastInterference;
  final List<int> _congruentRts = [];
  final List<int> _incongruentRts = [];

  static StroopState _seed(GameStore store, int round) => (
    phase: GamePhase.intro,
    level: store.getInt(CsStoreKeys.stroopLevel) ?? 1,
    idx: 0,
    round: round,
    stim: null,
    picked: null,
    fb: null,
    summary: null,
    levelMsg: null,
  );

  void _publish() => emit((
    phase: _phase,
    level: _level,
    idx: _idx,
    round: _round,
    stim: _stim,
    picked: _picked,
    fb: _fb,
    summary: _summary,
    levelMsg: _levelMsg,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _level = store.getInt(CsStoreKeys.stroopLevel) ?? 1;
    _staircase = LevelStaircase(
      level: _level,
      min: 1,
      max: 5,
      upThreshold: stroopUpThreshold,
      downThreshold: stroopDownThreshold,
      lowerIsBetter: true,
      streak: store.getInt(CsStoreKeys.stroopStreak) ?? 0,
    );
    _lastInterference = store.getInt(CsStoreKeys.stroopInterference);
    _idx = 0;
    _congruentRts.clear();
    _incongruentRts.clear();
    _summary = null;
    _levelMsg = null;
    _phase = GamePhase.playing;
    _publish();
    _trial();
  }

  void _trial() {
    clearTimers();
    _resolved = false;
    _stim = generateStroopStim(_level, _random);
    _picked = null;
    _fb = null;
    _shownAt = clock.now();
    _publish();
    final windowMs = stroopParamsForLevel(_level).windowMs;
    after(Duration(milliseconds: windowMs), () {
      if (!_resolved) _resolve(null); // deadline missed → wrong
    });
  }

  /// Taps the shape [shapeId] from the options.
  void pick(int shapeId) {
    if (_phase == GamePhase.playing && !_resolved) _resolve(shapeId);
  }

  void _resolve(int? shapeId) {
    _resolved = true;
    clearTimers();
    final stim = _stim!;
    final windowMs = stroopParamsForLevel(_level).windowMs;
    // A miss (null) takes the full window as its response time.
    final rt = shapeId == null
        ? windowMs
        : clock.now().difference(_shownAt).inMilliseconds.clamp(0, windowMs);
    (stim.congruent ? _congruentRts : _incongruentRts).add(rt);
    final correct = shapeId == stim.shape;
    _picked = shapeId;
    _fb = correct ? StroopFeedback.hit : StroopFeedback.wrong;
    _publish(); // stimulus stays visible through the feedback motion
    after(stroopFeedback, _advance);
  }

  void _advance() {
    clearTimers();
    _idx += 1;
    if (_idx >= _round) {
      _finish();
    } else {
      _trial();
    }
  }

  /// Interference cost: mean incongruent RT − mean congruent RT (ms). With an
  /// empty bucket its mean is treated as 0, so a round of all-congruent (or
  /// all-incongruent) trials yields a defined, non-negative-clamped value.
  int _interference() {
    final cong = _mean(_congruentRts);
    final incong = _mean(_incongruentRts);
    return jsRound(incong - cong);
  }

  static double _mean(List<int> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  void _finish() {
    clearTimers();
    final interference = _interference();
    final playedLevel = _staircase.level;
    final change = _staircase.recordRound(interference);
    final newLevel = _staircase.level;
    _levelMsg = change > 0
        ? 'Level up · L$newLevel'
        : change < 0
        ? 'Eased to L$newLevel'
        : null;
    final last = _lastInterference;

    store
      ..setInt(CsStoreKeys.stroopLevel, newLevel)
      ..setInt(CsStoreKeys.stroopStreak, _staircase.streak)
      ..setInt(CsStoreKeys.stroopInterference, interference);
    final norm = normalize('stroop', (
      interferenceMs: interference,
      level: playedLevel,
    ));
    unawaited(sink.recordResult(Domains.attentionInhibition, norm));

    _phase = GamePhase.round;
    _stim = null;
    _picked = null;
    _fb = null;
    _level = newLevel;
    _summary = (
      interferenceMs: interference,
      playedLevel: playedLevel,
      interferenceDelta: last == null ? null : interference - last,
    );
    _publish();
  }
}
