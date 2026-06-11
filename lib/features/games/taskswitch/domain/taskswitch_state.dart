import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart';

export 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart'
    show SwitchRule, SwitchStim, switchOptionLabels;

/// The feedback motion a resolved Task Switching trial shows.
enum SwitchFeedback {
  /// Judged the active rule correctly — ring bloom.
  hit,

  /// Wrong judgement (or let the window lapse) — shake.
  wrong,
}

/// The end-of-round summary. `accDelta` is `acc - lastAcc` (null on the first
/// play); the widget maps it to a `Delta`, keeping the engine Flutter-free.
typedef SwitchSummary = ({int acc, int playedLevel, int? accDelta});

/// Immutable snapshot the `TaskSwitchEngine` republishes to its controller.
typedef TaskSwitchState = ({
  /// Current phase.
  GamePhase phase,

  /// Current difficulty level (1–5).
  int level,

  /// Current trial index (0-based; drives the progress counter).
  int idx,

  /// Total trials this round.
  int round,

  /// The active rule to judge this trial (drives the banner + button labels).
  SwitchRule rule,

  /// The current stimulus, or null before the first trial / after the round.
  SwitchStim? stim,

  /// The option index the player tapped this trial, or null mid-trial.
  int? picked,

  /// The resolved-trial feedback, or null mid-trial.
  SwitchFeedback? fb,

  /// The round summary, set at finish.
  SwitchSummary? summary,

  /// Level-up / eased-down message for the RoundEnd, or null.
  String? levelMsg,
});
