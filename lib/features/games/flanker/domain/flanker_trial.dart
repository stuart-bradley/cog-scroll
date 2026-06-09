import 'dart:math';

import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';

/// The per-level display + timing parameters for a Flanker round (`SPEC.md`
/// §7.1). The colour-bound levers of the prototype are reinterpreted for mono
/// as the congruent mix, flanker count, response window, and flanker size:
///
/// - **L1** one flanker/side, all **congruent** (the easy floor — no
///   interference).
/// - **L2** one flanker/side, **incongruent**-heavy mix.
/// - **L3** two flankers/side, incongruent-heavy.
/// - **L4** + a 500 ms response window.
/// - **L5** + a 300 ms window and flankers the same size as the target.
typedef FlankerParams = ({
  /// Probability a trial's flankers point the same way as the target. L1 is 1.0
  /// (all congruent); above it the prototype's 0.4 keeps a classic flanker mix
  /// of interspersed congruent/incongruent trials so they stay unpredictable.
  double congruentRate,

  /// Flankers drawn on each side of the target (1 or 2).
  int flankersPerSide,

  /// Response window in ms — the countdown length and the resolve timeout.
  int windowMs,

  /// Whether the flankers are the same size as the target (L5; harder to
  /// ignore). Below L5 the flankers are smaller.
  bool fullSizeFlankers,
});

/// The lenient response window used below L4 (the prototype's 1300 ms).
const int flankerBaseWindowMs = 1300;

/// Congruent-trial probability above L1 — the prototype's classic flanker mix.
const double flankerCongruentRate = 0.4;

/// Resolves the [FlankerParams] for difficulty [level] (clamped to 1–5).
FlankerParams flankerParamsForLevel(int level) {
  final l = level.clamp(1, 5);
  return (
    congruentRate: l == 1 ? 1 : flankerCongruentRate,
    flankersPerSide: l <= 2 ? 1 : 2,
    windowMs: l >= 5
        ? 300
        : l == 4
        ? 500
        : flankerBaseWindowMs,
    fullSizeFlankers: l >= 5,
  );
}

/// Picks a random target direction for the next trial. [random] is injected for
/// determinism in tests.
FlankerDir randomFlankerDir(Random random) =>
    random.nextBool() ? FlankerDir.right : FlankerDir.left;

/// Generates the next trial: a random target [FlankerDir] and a per-trial
/// congruent/incongruent draw against the level's `congruentRate` (L1 is always
/// congruent). [random] is injected for determinism in tests.
FlankerStim generateFlankerStim(int level, Random random) {
  final dir = randomFlankerDir(random);
  final congruent =
      random.nextDouble() < flankerParamsForLevel(level).congruentRate;
  return (dir: dir, congruent: congruent);
}
