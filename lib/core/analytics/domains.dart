/// The six tracked cognitive domains and their derived trend type.
///
/// Domain names are verbatim from `docs/design/cs-data.jsx` and are the keys
/// used throughout analytics, scoring, and the dashboard.
abstract final class Domains {
  /// Working Memory (n-back, digit span).
  static const workingMemory = 'Working Memory';

  /// Processing Speed (reaction time).
  static const processingSpeed = 'Processing Speed';

  /// Attention & Inhibition (go/no-go, stroop).
  static const attentionInhibition = 'Attention & Inhibition';

  /// Mental Flexibility (trail making, task switching).
  static const mentalFlexibility = 'Mental Flexibility';

  /// Spatial Reasoning (corsi).
  static const spatialReasoning = 'Spatial Reasoning';

  /// Sustained Attention (flanker).
  static const sustainedAttention = 'Sustained Attention';

  /// All six domains, in radar order (clockwise from top).
  static const all = <String>[
    workingMemory,
    processingSpeed,
    attentionInhibition,
    mentalFlexibility,
    spatialReasoning,
    sustainedAttention,
  ];
}

/// Short two-line labels for the radar's spoke captions (the long domain names
/// don't fit around the hexagon). Verbatim from `docs/design/cs-data.jsx`.
const Map<String, List<String>> kDomainShort = {
  Domains.workingMemory: ['WORKING', 'MEMORY'],
  Domains.processingSpeed: ['PROCESS', 'SPEED'],
  Domains.attentionInhibition: ['ATTENTION', '& INHIB'],
  Domains.mentalFlexibility: ['MENTAL', 'FLEX'],
  Domains.spatialReasoning: ['SPATIAL', 'REASON'],
  Domains.sustainedAttention: ['SUSTAIN', 'ATTN'],
};

/// The direction of a domain's recent trend, or [none] when under-measured.
enum TrendState {
  /// Fewer than three results — not enough to classify.
  none,

  /// Recent results beat earlier ones by at least the stable threshold.
  improving,

  /// Earlier results beat recent ones by at least the stable threshold.
  declining,

  /// Within the stable threshold either way.
  stable,
}

/// A domain trend: its `state`, the rounded recent-minus-earlier point `delta`
/// ("up" already means better), and the result count `n` it was derived from.
typedef DomainTrend = ({TrendState state, int delta, int n});
