import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_trial.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Default trial count for a full (non-runner) round.
const int flankerDefaultRound = 20;

const Duration _feedback = Duration(milliseconds: 620);

/// Pure Flanker engine (Sustained Attention). Tap the way the *middle* arrow
/// points, ignoring the flankers. A two-consecutive-rounds ±1 staircase rides a
/// difficulty level (1–5; up when round accuracy > 85%, down when < 60%) whose
/// per-level display/timing params come from `flankerParamsForLevel`. Ports
/// `docs/design/cs-attention.jsx`, with the difficulty system restored per
/// `SPEC.md` §7.
class FlankerEngine extends GameEngine<FlankerState> {
  /// Creates an engine. [round] / [random] are injectable for tests; otherwise
  /// the round length comes from the runner (abbreviated) or the full default.
  // Not super-params: the initializer reads `store` to seed the snapshot.
  // ignore: use_super_parameters
  FlankerEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? round,
    Random? random,
  }) : _round = round ?? runner?.trials ?? flankerDefaultRound,
       _random = random ?? Random(),
       _level = store.getInt(CsStoreKeys.flankerLevel) ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(store, round ?? runner?.trials ?? flankerDefaultRound),
       );

  final int _round;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _level;
  int _idx = 0;
  FlankerDir? _dir;
  FlankerFeedback? _fb;
  FlankerSummary? _summary;
  String? _levelMsg;

  bool _resolved = false;
  final List<bool> _results = [];
  late LevelStaircase _staircase;
  int? _lastAcc;

  static FlankerState _seed(GameStore store, int round) => (
    phase: GamePhase.intro,
    level: store.getInt(CsStoreKeys.flankerLevel) ?? 1,
    round: round,
    idx: 0,
    dir: null,
    fb: null,
    summary: null,
    levelMsg: null,
  );

  void _publish() => emit((
    phase: _phase,
    level: _level,
    round: _round,
    idx: _idx,
    dir: _dir,
    fb: _fb,
    summary: _summary,
    levelMsg: _levelMsg,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _level = store.getInt(CsStoreKeys.flankerLevel) ?? 1;
    _staircase = LevelStaircase(
      level: _level,
      min: 1,
      max: 5,
      upThreshold: 85,
      downThreshold: 60,
      streak: store.getInt(CsStoreKeys.flankerStreak) ?? 0,
    );
    _lastAcc = store.getInt(CsStoreKeys.flankerAcc);
    _idx = 0;
    _results.clear();
    _summary = null;
    _levelMsg = null;
    _phase = GamePhase.playing;
    _publish();
    _trial();
  }

  void _trial() {
    clearTimers();
    _resolved = false;
    _dir = randomFlankerDir(_random);
    _fb = null;
    _publish();
    final windowMs = flankerParamsForLevel(_level).windowMs;
    after(Duration(milliseconds: windowMs), () {
      if (!_resolved) _resolve(null); // deadline missed → wrong
    });
  }

  /// The player's response: the side the middle arrow points.
  void respond(FlankerDir side) {
    if (_phase == GamePhase.playing && !_resolved) _resolve(side);
  }

  void _resolve(FlankerDir? side) {
    _resolved = true;
    clearTimers();
    final correct = side == _dir;
    _results.add(correct);
    _fb = correct ? FlankerFeedback.hit : FlankerFeedback.wrong;
    _publish(); // stimulus stays visible through the feedback motion
    after(_feedback, _advance);
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

  void _finish() {
    clearTimers();
    final correct = _results.where((c) => c).length;
    final acc = jsRound(correct / _round * 100);
    final playedLevel = _staircase.level;
    final change = _staircase.recordRound(acc);
    final newLevel = _staircase.level;
    _levelMsg = change > 0
        ? 'Level up · L$newLevel'
        : change < 0
        ? 'Eased to L$newLevel'
        : null;
    final lastAcc = _lastAcc;
    final accDelta = lastAcc == null ? null : acc - lastAcc;

    store
      ..setInt(CsStoreKeys.flankerLevel, newLevel)
      ..setInt(CsStoreKeys.flankerStreak, _staircase.streak)
      ..setInt(CsStoreKeys.flankerAcc, acc);
    final norm = normalize('flanker-acc', (acc: acc, level: playedLevel));
    unawaited(sink.recordResult(Domains.sustainedAttention, norm));

    _phase = GamePhase.round;
    _dir = null;
    _fb = null;

    final activeRunner = runner;
    if (activeRunner != null) {
      _publish();
      activeRunner.onDone(norm);
      return;
    }
    _level = newLevel;
    _summary = (acc: acc, playedLevel: playedLevel, accDelta: accDelta);
    _publish();
  }
}
