/// Canonical `shared_preferences` key names, mirroring the prototype's
/// `cogscroll:`-prefixed localStorage keys 1:1 (`docs/design/cs-data.jsx`).
///
/// Centralised so a typo can't silently split a read from its write. The
/// `cogscroll:` prefix is applied by `CsStore` (see `cs_store.dart`), not here.
abstract final class CsStoreKeys {
  /// Baseline onboarding completed; cleared by a baseline redo.
  static const onboarded = 'onboarded';

  /// First-run baseline prompt shown.
  static const baselinePrompted = 'baselinePrompted';

  /// Today's adaptive session set (`{date, steps, done}`).
  static const session = 'session';

  /// Daily reminder enabled.
  static const notify = 'notify';

  /// Daily reminder time (`{h, m}`).
  static const notifyTime = 'notifyTime';

  /// First-launch timestamp (ms since epoch) anchoring the 28-day trial.
  static const trialStart = 'trialStart';

  /// Persisted n-back staircase level.
  static const nbackN = 'nback-n';

  /// Persisted n-back consecutive-qualifying-round streak (two-consecutive ±1).
  static const nbackStreak = 'nback-streak';

  /// Display-only last n-back accuracy.
  static const nbackAcc = 'nback-acc';

  /// Persisted flanker staircase level (1–5).
  static const flankerLevel = 'flanker-level';

  /// Persisted flanker streak (two-consecutive ±1 staircase).
  static const flankerStreak = 'flanker-streak';

  /// Persisted go/no-go staircase level (1–5).
  static const gngLevel = 'gng-level';

  /// Persisted go/no-go streak (two-consecutive ±1 staircase).
  static const gngStreak = 'gng-streak';

  /// Persisted forward digit-span best span (resume level / RoundEnd delta).
  static const digitSpanFwd = 'digit-span-fwd';

  /// Persisted backward digit-span best span (resume level / RoundEnd delta).
  static const digitSpanBwd = 'digit-span-bwd';

  /// Persisted corsi best span.
  static const corsiSpan = 'corsi-span';

  /// Display-only last stroop accuracy.
  static const stroopAcc = 'stroop-acc';

  /// Display-only last flanker accuracy.
  static const flankerAcc = 'flanker-acc';

  /// Display-only last go/no-go accuracy.
  static const gngAcc = 'gng-acc';

  /// Display-only last task-switch accuracy.
  static const switchAcc = 'switch-acc';

  /// Display-only last trail-making time (s).
  static const trailTime = 'trail-time';

  /// Display-only last reaction-time average (ms).
  static const rtAvg = 'rt-avg';

  /// Cached Play entitlement — offline fallback only, never authoritative.
  static const purchasedCache = 'purchasedCache';

  /// Per-game analytics keys wiped by a baseline redo (SPEC §4.4). Excludes
  /// [onboarded] (also cleared, handled alongside the Drift wipe) and the Drift
  /// analytics themselves.
  static const perfKeys = <String>[
    nbackN,
    nbackStreak,
    nbackAcc,
    flankerLevel,
    flankerStreak,
    gngLevel,
    gngStreak,
    digitSpanFwd,
    digitSpanBwd,
    corsiSpan,
    stroopAcc,
    flankerAcc,
    gngAcc,
    switchAcc,
    trailTime,
    rtAvg,
  ];

  /// Keys that must never cross the backup boundary — entitlement and trial
  /// control. Excluded from both export and import so a backup file can neither
  /// grant entitlement ([purchasedCache] stays Play-derived) nor reset the
  /// trial ([trialStart] stays set-once on first launch).
  static const nonPortableKeys = <String>[purchasedCache, trialStart];
}
