import 'dart:math';

import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';

/// The per-level display + timing parameters for a Flanker round (`SPEC.md`
/// §7.1). The colour-bound levers of the prototype are reinterpreted for mono
/// as flanker count, response window, and flanker size:
///
/// - **L1** one flanker/side, **congruent** (no interference).
/// - **L2** one flanker/side, **incongruent**.
/// - **L3** two flankers/side, incongruent.
/// - **L4** + a 500 ms response window.
/// - **L5** + a 300 ms window and flankers the same size as the target.
typedef FlankerParams = ({
  /// Whether the flankers point the same way as the target.
  bool congruent,

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

/// Resolves the [FlankerParams] for difficulty [level] (clamped to 1–5).
FlankerParams flankerParamsForLevel(int level) {
  final l = level.clamp(1, 5);
  return (
    congruent: l == 1,
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
