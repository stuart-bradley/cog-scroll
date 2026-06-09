import 'dart:async';
import 'dart:math';

import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_sequence.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// Trial count for a Digit Span round (catalog-only — no runner).
const int digitSpanTrials = 6;

const Duration _showStart = Duration(milliseconds: 350);
const Duration _digitShown = Duration(milliseconds: 720);
const Duration _digitGap = Duration(milliseconds: 980);
const Duration _feedback = Duration(milliseconds: 950);

/// Pure Digit Span engine (Working Memory) — **catalog-only** (no runner).
/// Digits flash one at a time; recall them on a keypad. Forward mode recalls in
/// the same order; **backward mode recalls in reverse**. A within-play ±1 span
/// staircase resumes from the persisted best (forward cold-start 4 / floor 3;
/// backward cold-start 3 / floor 2). Ports `docs/design/cs-memory.jsx`, with
/// backward recall restored per `SPEC.md` §7.
class DigitSpanEngine extends GameEngine<DigitSpanState> {
  /// Creates an engine for [mode]. [random] is injectable for tests.
  // Not super-params: the initializer reads `mode` to seed the snapshot.
  // ignore: use_super_parameters
  DigitSpanEngine({
    required this.mode,
    required GameSink sink,
    required GameStore store,
    required Clock clock,
    Timers timers = const RealTimers(),
    Random? random,
  }) : _random = random ?? Random(),
       super(
         sink: sink,
         store: store,
         clock: clock,
         timers: timers,
         initial: _seed(mode),
       );

  /// Forward (same order) or backward (reverse order) recall.
  final DigitSpanMode mode;

  final Random _random;

  GamePhase _phase = GamePhase.intro;
  DigitSpanStage _stage = DigitSpanStage.show;
  int _trial = 0;
  int? _digit;
  List<int> _input = const [];
  DigitSpanFeedback? _fb;
  DigitSpanSummary? _summary;

  bool _resolved = false;
  List<int> _seq = const [];
  late SpanStaircase _staircase;
  int? _lastBest;

  /// Cold-start span: forward 4, backward 3.
  int get _startFloor => mode == DigitSpanMode.forward ? 4 : 3;

  /// Floor the within-play staircase never drops below: forward 3, backward 2.
  int get _minSpan => mode == DigitSpanMode.forward ? 3 : 2;

  /// Mode-specific persisted best key.
  String get _key => mode == DigitSpanMode.forward
      ? CsStoreKeys.digitSpanFwd
      : CsStoreKeys.digitSpanBwd;

  static DigitSpanState _seed(DigitSpanMode mode) => (
    phase: GamePhase.intro,
    mode: mode,
    stage: DigitSpanStage.show,
    level: mode == DigitSpanMode.forward ? 4 : 3,
    trial: 0,
    trials: digitSpanTrials,
    digit: null,
    input: const [],
    fb: null,
    summary: null,
  );

  void _publish() => emit((
    phase: _phase,
    mode: mode,
    stage: _stage,
    level: _staircase.level,
    trial: _trial,
    trials: digitSpanTrials,
    digit: _digit,
    input: _input,
    fb: _fb,
    summary: _summary,
  ));

  /// Begins a round (from intro or after a standalone round-end).
  void start() {
    clearTimers();
    final persistedBest = store.getInt(_key);
    final startLevel = persistedBest == null
        ? _startFloor
        : max(_minSpan, persistedBest);
    _staircase = SpanStaircase(level: startLevel, minSpan: _minSpan);
    _lastBest = persistedBest;
    _trial = 0;
    _summary = null;
    _phase = GamePhase.playing;
    _present();
  }

  void _present() {
    clearTimers();
    _resolved = false;
    _input = const [];
    _seq = buildDigitSequence(_staircase.level, _random);
    _stage = DigitSpanStage.show;
    _digit = null;
    _fb = null;
    _publish();
    var t = _showStart;
    for (final d in _seq) {
      after(t, () {
        _digit = d;
        _publish();
      });
      after(t + _digitShown, () {
        _digit = null;
        _publish();
      });
      t += _digitGap;
    }
    after(t, () {
      _stage = DigitSpanStage.recall;
      _publish();
    });
  }

  /// Taps digit [d] on the keypad during recall.
  void pad(int d) {
    if (_resolved || _stage != DigitSpanStage.recall) return;
    _input = [..._input, d];
    _publish();
    if (_input.length >= _staircase.level) _judge();
  }

  void _judge() {
    _resolved = true;
    clearTimers();
    final target = mode == DigitSpanMode.forward
        ? _seq
        : _seq.reversed.toList();
    final correct = _sequenceEquals(_input, target);
    _staircase.recordTrial(correct: correct);
    _fb = correct ? DigitSpanFeedback.hit : DigitSpanFeedback.wrong;
    _publish(); // digits stay visible through the feedback motion
    _trial += 1;
    after(_feedback, _advance);
  }

  static bool _sequenceEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _advance() {
    clearTimers();
    if (_trial >= digitSpanTrials) {
      _finish();
    } else {
      _present();
    }
  }

  void _finish() {
    clearTimers();
    final best = _staircase.best;
    store.setInt(_key, best);
    final norm = normalize('digit-span', (span: best, mode: mode));
    unawaited(sink.recordResult(Domains.workingMemory, norm));

    _phase = GamePhase.round;
    _digit = null;
    _fb = null;
    _input = const [];
    final lastBest = _lastBest;
    final spanDelta = lastBest == null ? null : best - lastBest;
    _summary = (span: best, spanDelta: spanDelta);
    _publish();
  }
}
