/// One step of the first-run baseline: a runner-capable game id and the
/// abbreviated length it runs at (exactly one of `trials` / `points`).
///
/// The domain a step feeds is **not** stored here — it is read from
/// `GameRegistry.byId(id).domain`, so the baseline can't drift from a game's
/// registered domain.
typedef BaselineStep = ({String id, int? trials, int? points});

/// The six baseline games — one per cognitive domain, in fixed play order —
/// each abbreviated to keep the whole run under ~5 minutes. Ports the
/// prototype's `BASELINE_SET` (`docs/design/cs-onboarding.jsx`), mapping its
/// `trails` id to this project's Mode-A descriptor `trails-a`.
const baselineSet = <BaselineStep>[
  (id: 'reaction', trials: 5, points: null), // Processing Speed
  (id: 'flanker', trials: 10, points: null), // Sustained Attention
  (id: 'gonogo', trials: 12, points: null), // Attention & Inhibition
  (id: 'nback', trials: 10, points: null), // Working Memory
  (id: 'corsi', trials: 4, points: null), // Spatial Reasoning
  (id: 'trails-a', trials: null, points: 8), // Mental Flexibility
];
