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
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart';

/// Trial count for a Task Switching round (catalog-only — no runner).
const int taskSwitchTrials = 20;

/// Post-resolve feedback window (the prototype's 600 ms). The correct-tap
/// Bloom is given this as its `duration` so it completes with the stimulus
/// visible (DESIGN non-negotiable); the wrong Shake (500 ms) already fits.
const Duration taskSwitchFeedback = Duration(milliseconds: 600);

/// Staircase up/down thresholds on accuracy (%), matching the other leveled
/// games (`SPEC.md` §7.1): up above 85, down below 60.
const int taskSwitchUpThreshold = 85;

/// See [taskSwitchUpThreshold].
const int taskSwitchDownThreshold = 60;

/// Random-switch probability when the level has no fixed cadence (L3+).
const double taskSwitchRandomRate = 0.5;

/// Pure Task Switching engine (Mental Flexibility) — **catalog-only** (no
/// runner). A banner names the active rule (judge shape / fill / size); the
/// rule keeps switching. A two-consecutive-rounds ±1 staircase rides a
/// difficulty level (1–5; escalating switch cadence, a tightening response
/// window, and a third rotating rule at L5). Ports `docs/design/cs-flex.jsx`,
/// with the size attribute and difficulty system restored per `SPEC.md` §7.
class TaskSwitchEngine extends GameEngine<TaskSwitchState> {
  /// Creates an engine. [round] / [random] are injectable for tests.
  // Not super-params: the initializer reads `store` to seed the snapshot.
  // ignore: use_super_parameters
  TaskSwitchEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    Timers timers = const RealTimers(),
    int? round,
    Random? random,
  }) : _round = round ?? taskSwitchTrials,
       _random = random ?? Random(),
       _level = store.getInt(CsStoreKeys.switchLevel) ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         timers: timers,
         initial: _seed(store, round ?? taskSwitchTrials),
       );

  final int _round;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _level;
  int _idx = 0;
  SwitchRule _rule = SwitchRule.shape;
  SwitchStim? _stim;
  int? _picked;
  SwitchFeedback? _fb;
  SwitchSummary? _summary;
  String? _levelMsg;

  bool _resolved = false;
  final List<bool> _results = [];
  late LevelStaircase _staircase;
  int? _lastAcc;

  static TaskSwitchState _seed(GameStore store, int round) => (
    phase: GamePhase.intro,
    level: store.getInt(CsStoreKeys.switchLevel) ?? 1,
    idx: 0,
    round: round,
    rule: SwitchRule.shape,
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
    rule: _rule,
    stim: _stim,
    picked: _picked,
    fb: _fb,
    summary: _summary,
    levelMsg: _levelMsg,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    _level = store.getInt(CsStoreKeys.switchLevel) ?? 1;
    _staircase = LevelStaircase(
      level: _level,
      min: 1,
      max: 5,
      upThreshold: taskSwitchUpThreshold,
      downThreshold: taskSwitchDownThreshold,
      streak: store.getInt(CsStoreKeys.switchStreak) ?? 0,
    );
    _lastAcc = store.getInt(CsStoreKeys.switchAcc);
    _idx = 0;
    _results.clear();
    _summary = null;
    _levelMsg = null;
    final rules = switchParamsForLevel(_level).rules;
    _rule = rules[_random.nextInt(rules.length)];
    _phase = GamePhase.playing;
    _publish();
    _trial();
  }

  void _trial() {
    clearTimers();
    _resolved = false;
    final params = switchParamsForLevel(_level);
    if (_idx > 0 && _shouldSwitch(params)) {
      _rule = _otherRule(_rule, params.rules);
    }
    _stim = generateSwitchStim(_level, _random);
    _picked = null;
    _fb = null;
    _publish();
    after(Duration(milliseconds: params.windowMs), () {
      if (!_resolved) _resolve(null); // deadline missed → wrong
    });
  }

  bool _shouldSwitch(SwitchParams params) {
    final cadence = params.cadence;
    if (cadence != null) return _idx % cadence == 0;
    return _random.nextDouble() < taskSwitchRandomRate;
  }

  SwitchRule _otherRule(SwitchRule current, List<SwitchRule> rules) {
    final others = rules.where((r) => r != current).toList();
    return others[_random.nextInt(others.length)];
  }

  /// Taps option [choice] (0 or 1) for the active rule.
  void pick(int choice) {
    if (_phase == GamePhase.playing && !_resolved) _resolve(choice);
  }

  void _resolve(int? choice) {
    _resolved = true;
    clearTimers();
    final stim = _stim!;
    final correct =
        choice != null && choice == switchCorrectChoice(_rule, stim);
    _results.add(correct);
    _picked = choice;
    _fb = correct ? SwitchFeedback.hit : SwitchFeedback.wrong;
    _publish(); // stimulus stays visible through the feedback motion
    after(taskSwitchFeedback, _advance);
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

    store
      ..setInt(CsStoreKeys.switchLevel, newLevel)
      ..setInt(CsStoreKeys.switchStreak, _staircase.streak)
      ..setInt(CsStoreKeys.switchAcc, acc);
    final norm = normalize('switch-acc', (acc: acc, level: playedLevel));
    unawaited(sink.recordResult(Domains.mentalFlexibility, norm));

    _phase = GamePhase.round;
    _stim = null;
    _picked = null;
    _fb = null;
    _level = newLevel;
    _summary = (
      acc: acc,
      playedLevel: playedLevel,
      accDelta: lastAcc == null ? null : acc - lastAcc,
    );
    _publish();
  }
}
