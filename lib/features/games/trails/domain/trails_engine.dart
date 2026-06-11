import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';
import 'package:cogscroll/features/games/trails/domain/trails_board.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';

/// Elapsed-time republish cadence (the prototype's 100 ms tick).
const Duration trailsTick = Duration(milliseconds: 100);

/// How long a wrong tap's shake-flash lasts (the prototype's 360 ms). The
/// shake motion is run at this duration so it completes within the flash.
const Duration trailsBadFlash = Duration(milliseconds: 360);

/// Staircase thresholds on seconds-per-target (lower is better), anchored to
/// the `SPEC.md` §4.3 norm tables: up when faster than the "good" band (Mode A
/// 1.7 s/t ≈ TMT-A good <20 s; Mode B 3.0 s/t ≈ TMT-B good <45 s), down when
/// slower than the table's mid-low band.
const double trailsAUpThreshold = 1.7;

/// See [trailsAUpThreshold].
const double trailsADownThreshold = 3.3;

/// See [trailsAUpThreshold].
const double trailsBUpThreshold = 3;

/// See [trailsAUpThreshold].
const double trailsBDownThreshold = 6;

/// Pure Trail Making engine (Mental Flexibility). Connect the targets in
/// order against the clock — Mode A numbers 1→N, Mode B alternating
/// 1→A→2→B…. A two-consecutive-rounds ±1 staircase rides a difficulty level
/// (1–5 = target count 8→25; faster s/target ⇒ up). A wrong tap shake-flashes
/// with no time penalty. Ports `docs/design/cs-flex.jsx`, with the difficulty
/// system restored per `SPEC.md` §7; elapsed time is taken as `Clock.now()`
/// deltas.
class TrailsEngine extends GameEngine<TrailsState> {
  /// Creates an engine for [mode]. [count] / [random] are injectable for
  /// tests; otherwise the target count comes from the runner (abbreviated
  /// `points`) or the level ladder.
  // Not super-params: the initializer reads `store`/`mode` to seed.
  // ignore: use_super_parameters
  TrailsEngine({
    required this.mode,
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? count,
    Random? random,
  }) : _countOverride = count ?? runner?.points,
       _random = random ?? Random(),
       _level = store.getInt(_levelKeyFor(mode)) ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(store, mode, count ?? runner?.points),
       );

  /// Mode A (numbers) or Mode B (number/letter alternation).
  final TrailMode mode;

  final int? _countOverride;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _level;
  int _count = 0;
  List<TrailTarget> _targets = const [];
  int _next = 0;
  int? _bad;
  double _elapsed = 0;
  TrailsSummary? _summary;
  String? _levelMsg;

  late LevelStaircase _staircase;
  late DateTime _startedAt;
  double? _lastPace;
  int _badSeq = 0;

  static String _levelKeyFor(TrailMode mode) =>
      mode == TrailMode.a ? CsStoreKeys.trailALevel : CsStoreKeys.trailBLevel;

  String get _levelKey => _levelKeyFor(mode);

  String get _streakKey =>
      mode == TrailMode.a ? CsStoreKeys.trailAStreak : CsStoreKeys.trailBStreak;

  String get _timeKey =>
      mode == TrailMode.a ? CsStoreKeys.trailATime : CsStoreKeys.trailBTime;

  double get _upThreshold =>
      mode == TrailMode.a ? trailsAUpThreshold : trailsBUpThreshold;

  double get _downThreshold =>
      mode == TrailMode.a ? trailsADownThreshold : trailsBDownThreshold;

  static TrailsState _seed(GameStore store, TrailMode mode, int? count) {
    final level = store.getInt(_levelKeyFor(mode)) ?? 1;
    return (
      phase: GamePhase.intro,
      mode: mode,
      level: level,
      count: count ?? trailCountForLevel(level),
      targets: const [],
      next: 0,
      bad: null,
      elapsed: 0,
      summary: null,
      levelMsg: null,
    );
  }

  void _publish() => emit((
    phase: _phase,
    mode: mode,
    level: _level,
    count: _count,
    targets: _targets,
    next: _next,
    bad: _bad,
    elapsed: _elapsed,
    summary: _summary,
    levelMsg: _levelMsg,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _level = store.getInt(_levelKey) ?? 1;
    _staircase = LevelStaircase(
      level: _level,
      min: 1,
      max: 5,
      upThreshold: _upThreshold,
      downThreshold: _downThreshold,
      lowerIsBetter: true,
      streak: store.getInt(_streakKey) ?? 0,
    );
    _lastPace = store.getDouble(_timeKey);
    _count = _countOverride ?? trailCountForLevel(_level);
    _targets = generateTrailTargets(
      count: _count,
      mode: mode,
      radius: trailRadiusForLevel(_level),
      random: _random,
    );
    _next = 0;
    _bad = null;
    _elapsed = 0;
    _summary = null;
    _levelMsg = null;
    _startedAt = clock.now();
    _phase = GamePhase.playing;
    _publish();
    // The tick only drives the standalone TopBar readout; under a runner the
    // TopBar is hidden, so skip the 100ms full-state republish there. Scoring
    // is unaffected — finish() measures elapsed time from clock.now() deltas.
    if (runner == null) _scheduleTick();
  }

  /// Taps the target at sequence [index]. In order → it fills (and the round
  /// finishes after the last); out of order → a 360 ms shake-flash, no
  /// advance, no time penalty.
  void tap(int index) {
    if (_phase != GamePhase.playing) return;
    if (index == _next) {
      _next += 1;
      _bad = null; // a correct tap ends any lingering wrong-flash
      if (_next >= _count) {
        _finish();
      } else {
        _publish();
      }
    } else {
      _flashBad(index);
    }
  }

  void _scheduleTick() {
    after(trailsTick, () {
      _elapsed = _secondsSinceStart();
      _publish();
      _scheduleTick();
    });
  }

  double _secondsSinceStart() =>
      clock.now().difference(_startedAt).inMilliseconds / 1000;

  /// Marks [index] wrong and clears it after [trailsBadFlash]. A sequence
  /// token (not a cancelled timer) keeps the latest flash at full length when
  /// wrong taps overlap, matching the prototype's `clearTimeout(badTimer)`.
  void _flashBad(int index) {
    _bad = index;
    final seq = ++_badSeq;
    _publish();
    after(trailsBadFlash, () {
      if (_badSeq == seq && _bad != null) {
        _bad = null;
        _publish();
      }
    });
  }

  void _finish() {
    clearTimers();
    final seconds = _secondsSinceStart();
    _elapsed = seconds;
    final pace = seconds / _count; // seconds per target (the scored metric)
    final playedLevel = _staircase.level;
    final change = _staircase.recordRound(pace);
    final newLevel = _staircase.level;
    _levelMsg = change > 0
        ? 'Level up · L$newLevel'
        : change < 0
        ? 'Eased to L$newLevel'
        : null;
    final lastPace = _lastPace;

    store
      ..setInt(_levelKey, newLevel)
      ..setInt(_streakKey, _staircase.streak)
      ..setDouble(_timeKey, pace);
    final norm = normalize('trail-time', (
      seconds: seconds,
      count: _count,
      mode: mode,
    ));
    unawaited(sink.recordResult(Domains.mentalFlexibility, norm));

    _phase = GamePhase.round;
    _bad = null;

    final activeRunner = runner;
    if (activeRunner != null) {
      _publish();
      activeRunner.onDone(norm);
      return;
    }
    _level = newLevel;
    _summary = (
      seconds: seconds,
      count: _count,
      playedLevel: playedLevel,
      paceDelta: lastPace == null ? null : pace - lastPace,
    );
    _publish();
  }
}
