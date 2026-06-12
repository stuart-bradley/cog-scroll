import 'dart:async';

import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baseline_controller.g.dart';

/// The three stages of the first-run baseline flow.
enum BaselineStage {
  /// The "Find your baseline" welcome screen.
  welcome,

  /// Playing the current game (`step`) of [baselineSet].
  playing,

  /// All games done/skipped — reveal the seeded radar.
  done,
}

/// The baseline flow snapshot: the current [BaselineStage] and the 0-based
/// index into [baselineSet] of the game being played.
typedef BaselineState = ({BaselineStage stage, int step});

/// Drives the first-run baseline flow (`welcome → six games → done`).
///
/// Pure flow logic, separate from the screen (which owns navigation and mounts
/// the games). Ports the prototype's `Baseline` component
/// (`docs/design/cs-onboarding.jsx`): `baselinePrompted` is set on entry (so an
/// early exit never re-nags), `onboarded` on completion. No step is persisted —
/// there is no mid-flow resume.
@riverpod
class BaselineController extends _$BaselineController {
  @override
  BaselineState build() {
    // Flow opened: record the first-run prompt was shown, even if the user
    // bails before finishing (prototype `cs-onboarding.jsx:87`).
    unawaited(
      ref.read(csStoreProvider).setJson(CsStoreKeys.baselinePrompted, true),
    );
    return (stage: BaselineStage.welcome, step: 0);
  }

  /// Begins the run from the welcome screen (→ first game).
  void start() => state = (stage: BaselineStage.playing, step: 0);

  /// Advances past the current game — called on a game's finish, its Skip, or
  /// the header Skip. After the last game, marks `onboarded` and moves to the
  /// radar reveal.
  void advance() {
    final next = state.step + 1;
    if (next >= baselineSet.length) {
      unawaited(ref.read(csStoreProvider).setJson(CsStoreKeys.onboarded, true));
      state = (stage: BaselineStage.done, step: state.step);
    } else {
      state = (stage: BaselineStage.playing, step: next);
    }
  }
}
