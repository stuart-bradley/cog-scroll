/// Rounds [x] half-up (toward positive infinity), matching JavaScript's
/// `Math.round`.
///
/// Dart's [num.round] rounds half away from zero, so it diverges from the React
/// prototype on negative `.5` values (e.g. a trend delta of `-2.5`: Dart gives
/// `-3`, JS gives `-2`). Routing every score/EMA/trend rounding through this
/// keeps output byte-identical to `docs/design/cs-data.jsx`.
int jsRound(num x) => (x + 0.5).floor();
