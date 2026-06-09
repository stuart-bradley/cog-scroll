import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/metrics.dart';
import 'package:cogscroll/core/scoring/nback_raw.dart';

// Piecewise-linear breakpoint tables `[rawX, score]`, raw value ascending. A
// table whose score column *descends* as raw ascends encodes a lower-is-better
// metric (`rt-avg`, `trail-time`, `stroop` interference), so "up" always means
// better downstream. The accuracy/time tables originate in `docs/design/
// cs-data.jsx`; the level lift (`eff`) generalises the prototype's n-back lift
// to every leveled game (`SPEC.md` §4.3) so a given accuracy/time scores higher
// at a harder level.
const List<List<double>> _nback = [
  [40, 15],
  [60, 35],
  [75, 58],
  [85, 78],
  [100, 100],
];
const List<List<double>> _flankerAcc = [
  [60, 10],
  [85, 35],
  [90, 58],
  [95, 80],
  [100, 100],
];
const List<List<double>> _gngAcc = [
  [60, 10],
  [85, 38],
  [92, 62],
  [97, 84],
  [100, 100],
];
const List<List<double>> _switchAcc = [
  [50, 12],
  [70, 40],
  [82, 60],
  [90, 78],
  [100, 100],
];
// Stroop interference cost in ms — lower is better (descending score).
const List<List<double>> _stroop = [
  [40, 100],
  [80, 82],
  [150, 55],
  [200, 30],
  [300, 8],
];
const List<List<double>> _corsiSpan = [
  [2, 10],
  [3, 25],
  [5, 55],
  [6, 68],
  [7, 82],
  [9, 100],
];
const List<List<double>> _digitSpanFwd = [
  [3, 15],
  [4, 30],
  [6, 55],
  [7, 68],
  [8, 82],
  [10, 100],
];
// Backward recall — shorter spans, so the curve shifts down vs forward.
const List<List<double>> _digitSpanBwd = [
  [2, 15],
  [3, 30],
  [4, 50],
  [5, 68],
  [6, 82],
  [8, 100],
];
const List<List<double>> _rtAvg = [
  [180, 100],
  [220, 82],
  [260, 62],
  [300, 45],
  [350, 28],
  [450, 8],
];
// Trail Making seconds-per-target — lower is better. Mode B (number/letter) is
// graded on a more lenient curve than Mode A (numbers only).
const List<List<double>> _trailA = [
  [1, 100],
  [1.7, 82],
  [2.5, 58],
  [3.3, 42],
  [5, 22],
  [7.5, 5],
];
const List<List<double>> _trailB = [
  [1.8, 100],
  [3, 82],
  [4.5, 58],
  [6, 42],
  [9, 22],
  [13.5, 5],
];

double _clamp(double x) => x.clamp(0, 100).toDouble();

/// Piecewise-linear interpolation of [x] across breakpoints [pts] (raw value
/// ascending), clamped to the first/last score outside the table's range.
double _piece(double x, List<List<double>> pts) {
  if (x <= pts.first[0]) return pts.first[1];
  for (var i = 1; i < pts.length; i++) {
    if (x <= pts[i][0]) {
      final x0 = pts[i - 1][0];
      final y0 = pts[i - 1][1];
      final x1 = pts[i][0];
      final y1 = pts[i][1];
      return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
  }
  return pts.last[1];
}

/// Leveled-accuracy score: lift accuracy by the level, then interpolate.
int _leveledAcc(LevelAcc raw, List<List<double>> table) {
  final eff = raw.acc + (raw.level - 1) * 10;
  return jsRound(_clamp(_piece(eff.toDouble(), table)));
}

/// Maps a raw game metric onto a 0–100 score versus population norms.
///
/// [key] selects the metric. Leveled / mode-aware metrics take a record (see
/// `metrics.dart`): `nback` → [NbackRaw]; `flanker-acc`/`gng-acc`/`switch-acc`
/// → [LevelAcc]; `stroop` → [StroopRaw]; `digit-span` → [DigitSpanRaw];
/// `trail-time` → [TrailRaw]. `corsi-span` and `rt-avg` take a [num]. Unknown
/// keys clamp-and-round the raw value. See `SPEC.md` §4.3.
int normalize(String key, Object raw) {
  switch (key) {
    case 'nback':
      final r = raw as NbackRaw;
      final eff = r.acc + (r.n - 2) * 15;
      return jsRound(_clamp(_piece(eff.toDouble(), _nback)));
    case 'flanker-acc':
      return _leveledAcc(raw as LevelAcc, _flankerAcc);
    case 'gng-acc':
      return _leveledAcc(raw as LevelAcc, _gngAcc);
    case 'switch-acc':
      return _leveledAcc(raw as LevelAcc, _switchAcc);
    case 'stroop':
      final r = raw as StroopRaw;
      // Higher level ⇒ more interference expected, so credit it back.
      final eff = r.interferenceMs - (r.level - 1) * 15;
      return jsRound(_clamp(_piece(eff.toDouble(), _stroop)));
    case 'corsi-span':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _corsiSpan)));
    case 'digit-span':
      final r = raw as DigitSpanRaw;
      final table = r.mode == DigitSpanMode.forward
          ? _digitSpanFwd
          : _digitSpanBwd;
      return jsRound(_clamp(_piece(r.span.toDouble(), table)));
    case 'rt-avg':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _rtAvg)));
    case 'trail-time':
      final r = raw as TrailRaw;
      final spt = r.seconds / r.count;
      final table = r.mode == TrailMode.a ? _trailA : _trailB;
      return jsRound(_clamp(_piece(spt, table)));
    default:
      return jsRound(_clamp((raw as num).toDouble()));
  }
}
