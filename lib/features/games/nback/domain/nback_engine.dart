import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/nback/domain/nback_sequence.dart';
import 'package:cogscroll/features/games/nback/domain/nback_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Default trial count for a full (non-runner) round.
const int nbackDefaultRound = 20;

const Duration _show = Duration(milliseconds: 1150);
const Duration _feedback = Duration(milliseconds: 760);
const Duration _correctRejectionBlank = Duration(milliseconds: 360);

/// Pure n-back engine (Working Memory). Tap when the shape matches the one N
/// back. N rides a two-consecutive-rounds ±1 staircase (start 1, cap 4; up when
/// round accuracy > 85%, down when < 60%). Ports `docs/design/cs-nback.jsx`,
/// with the staircase generalised per `SPEC.md` §7.
class NbackEngine extends GameEngine<NbackState> {
  /// Creates an engine. [round] / [random] are injectable for tests; otherwise
  /// the round length comes from the runner (abbreviated) or the full default.
  // Not super-params: the initializer reads `store` to seed N + the snapshot.
  // ignore: use_super_parameters
  NbackEngine({
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    RunnerContext? runner,
    Timers timers = const RealTimers(),
    int? round,
    Random? random,
  }) : _round = round ?? runner?.trials ?? nbackDefaultRound,
       _random = random ?? Random(),
       _n = store.getInt('nback-n') ?? 1,
       super(
         sink: sink,
         store: store,
         clock: clock,
         runner: runner,
         timers: timers,
         initial: _seed(store),
       );

  final int _round;
  final Random _random;

  GamePhase _phase = GamePhase.intro;
  int _n;
  int _idx = 0;
  int? _shape;
  bool _showing = false;
  NbackFeedback? _fb;
  NbackSummary? _summary;
  String? _levelMsg;

  List<int> _seq = const [];
  final List<bool> _results = [];
  bool _resolved = false;
  late LevelStaircase _staircase;
  int? _lastAcc;

  static NbackState _seed(GameStore store) => (
    phase: GamePhase.intro,
    n: store.getInt('nback-n') ?? 1,
    idx: 0,
    shape: null,
    showing: false,
    fb: null,
    summary: null,
    levelMsg: null,
  );

  void _publish() => emit((
    phase: _phase,
    n: _n,
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
    _n = store.getInt('nback-n') ?? 1;
    _staircase = LevelStaircase(
      level: _n,
      min: 1,
      max: 4,
      upThreshold: 85,
      downThreshold: 60,
      streak: store.getInt('nback-streak') ?? 0,
    );
    _lastAcc = store.getInt('nback-acc');
    _seq = buildNbackSequence(_n, _round, _random);
    _idx = 0;
    _results.clear();
    _summary = null;
    _levelMsg = null;
    _phase = GamePhase.playing;
    _publish();
    _trial();
  }

  /// The player's "Match" input.
  void tap() {
    if (_phase == GamePhase.playing && !_resolved) _resolve(tapped: true);
  }

  void _trial() {
    clearTimers();
    _resolved = false;
    _shape = _seq[_idx];
    _showing = true;
    _fb = null;
    _publish();
    after(_show, () {
      if (!_resolved) _resolve(tapped: false);
    });
  }

  void _resolve({required bool tapped}) {
    _resolved = true;
    clearTimers();
    final i = _idx;
    final truth = i >= _n && _seq[i] == _seq[i - _n];
    final bool correct;
    final NbackFeedback? fb;
    if (tapped) {
      correct = truth;
      fb = truth ? NbackFeedback.hit : NbackFeedback.wrong;
    } else {
      correct = !truth;
      fb = truth ? NbackFeedback.wrong : null; // miss = wrong; reject = quiet
    }
    _results.add(correct);
    if (fb != null) {
      _fb = fb;
      _showing = true;
      _publish();
      after(_feedback, _advance);
    } else {
      _fb = null;
      _showing = false; // blank between trials, only after the motion window
      _publish();
      after(_correctRejectionBlank, _advance);
    }
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
    final playedN = _staircase.level;
    final change = _staircase.recordRound(acc);
    final newN = _staircase.level;
    _levelMsg = change > 0
        ? 'Level up · $newN-back'
        : change < 0
        ? 'Eased to $newN-back'
        : null;
    final lastAcc = _lastAcc;
    final accDelta = lastAcc == null ? null : acc - lastAcc;

    store
      ..setInt('nback-n', newN)
      ..setInt('nback-streak', _staircase.streak)
      ..setInt('nback-acc', acc);
    final norm = normalize('nback', (acc: acc, n: playedN));
    unawaited(sink.recordResult(Domains.workingMemory, norm));

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
    _n = newN;
    _summary = (acc: acc, playedN: playedN, accDelta: accDelta);
    _publish();
  }
}
