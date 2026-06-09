import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_state.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Default trial count for a full (non-runner) round.
const int goNoGoDefaultRound = 24;

/// Pure Go/No-Go engine (Attention & Inhibition). Tap for the circle (Go),
/// withhold for the square/hexagon (No-Go). A two-consecutive-rounds ±1
/// staircase rides a difficulty level (1–5; up when round accuracy > 85%, down
/// when < 60%) whose Go ratio, ISI, and No-Go shape come from
/// `goNoGoParamsForLevel`. Ports `docs/design/cs-attention.jsx`, with the
/// difficulty system restored per `SPEC.md` §7.
class GoNoGoEngine extends GameEngine<GngState> {
  /// Creates an engine. [round] / [random] are injectable for tests; otherwise
  /// the round length comes from the runner (abbreviated) or the full default.
  // Not super-params: the initializer reads `store` to seed the snapshot.
  // ignore: use_super_parameters
  GoNoGoEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? round,
    Random? random,
  }) : _round = round ?? runner?.trials ?? goNoGoDefaultRound,
       _random = random ?? Random(),
       _level = store.getInt(CsStoreKeys.gngLevel) ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(store, round ?? runner?.trials ?? goNoGoDefaultRound),
       );

  final int _round;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _level;
  int _idx = 0;
  int? _shape;
  bool _showing = false;
  GngFeedback? _fb;
  GngSummary? _summary;
  String? _levelMsg;

  bool _resolved = false;
  bool _isGo = false;
  final List<bool> _results = [];
  late LevelStaircase _staircase;
  int? _lastAcc;

  static GngState _seed(GameStore store, int round) => (
    phase: GamePhase.intro,
    level: store.getInt(CsStoreKeys.gngLevel) ?? 1,
    round: round,
    idx: 0,
    shape: null,
    showing: false,
    fb: null,
    summary: null,
    levelMsg: null,
  );

  void _publish() => emit((
    phase: _phase,
    level: _level,
    round: _round,
    idx: _idx,
    shape: _shape,
    showing: _showing,
    fb: _fb,
    summary: _summary,
    levelMsg: _levelMsg,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _level = store.getInt(CsStoreKeys.gngLevel) ?? 1;
    _staircase = LevelStaircase(
      level: _level,
      min: 1,
      max: 5,
      upThreshold: 85,
      downThreshold: 60,
      streak: store.getInt(CsStoreKeys.gngStreak) ?? 0,
    );
    _lastAcc = store.getInt(CsStoreKeys.gngAcc);
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
    final trial = generateGngTrial(goNoGoParamsForLevel(_level), _random);
    _isGo = trial.isGo;
    _shape = trial.shape;
    _showing = true;
    _fb = null;
    _publish();
    after(const Duration(milliseconds: gngDisplayMs), () {
      if (!_resolved) _resolve(tapped: false);
    });
  }

  /// The player's tap (the Go response).
  void tap() {
    if (_phase == GamePhase.playing && !_resolved) _resolve(tapped: true);
  }

  void _resolve({required bool tapped}) {
    _resolved = true;
    clearTimers();
    final correct = tapped ? _isGo : !_isGo;
    _results.add(correct);
    _fb = !correct
        ? GngFeedback.wrong
        : _isGo
        ? GngFeedback.correctGo
        : GngFeedback.correctWithhold;
    _publish(); // stimulus stays visible through the feedback motion
    after(gngFeedbackWindow, _advance);
  }

  void _advance() {
    clearTimers();
    _showing = false;
    _fb = null;
    _publish(); // the blank inter-stimulus interval
    final isi = goNoGoParamsForLevel(_level).isiMs;
    after(Duration(milliseconds: isi), () {
      _idx += 1;
      if (_idx >= _round) {
        _finish();
      } else {
        _trial();
      }
    });
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
      ..setInt(CsStoreKeys.gngLevel, newLevel)
      ..setInt(CsStoreKeys.gngStreak, _staircase.streak)
      ..setInt(CsStoreKeys.gngAcc, acc);
    final norm = normalize('gng-acc', (acc: acc, level: playedLevel));
    unawaited(sink.recordResult(Domains.attentionInhibition, norm));

    _phase = GamePhase.round;
    _shape = null;
    _showing = false;
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
