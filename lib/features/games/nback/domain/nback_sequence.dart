import 'dart:math';

/// Number of distinct shapes the n-back sequence draws from (0–5).
const int nbackShapeCount = 6;

/// Probability that a position `i ≥ n` is an intentional n-back match.
const double nbackMatchRate = 0.32;

/// Builds a [length]-long shape sequence for an [n]-back round.
///
/// Each position `i ≥ n` is, with probability [nbackMatchRate], a match
/// (repeats `seq[i - n]`); otherwise a random shape chosen to *not*
/// coincidentally equal `seq[i - n]`, so the only matches are intended. Ported
/// from `docs/design/cs-nback.jsx`. [random] is injected for determinism.
List<int> buildNbackSequence(int n, int length, Random random) {
  final s = <int>[];
  for (var i = 0; i < length; i++) {
    if (i >= n && random.nextDouble() < nbackMatchRate) {
      s.add(s[i - n]);
      continue;
    }
    int c;
    do {
      c = random.nextInt(nbackShapeCount);
    } while (i >= n && c == s[i - n]);
    s.add(c);
  }
  return s;
}
