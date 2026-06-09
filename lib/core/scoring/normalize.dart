import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/nback_raw.dart';

// Piecewise-linear breakpoint tables `[rawX, score]`, raw value ascending.
// Ported verbatim from `docs/design/cs-data.jsx`. Lower-is-better metrics
// (`rt-avg`, `trail-time`) map a rising raw value to a falling score, so "up"
// always means better for everything downstream.
const List<List<double>> _nback = [
  [40, 15],
  [60, 35],
  [75, 58],
  [85, 78],
  [100, 100],
];
const List<List<double>> _digitSpan = [
  [3, 15],
  [4, 30],
  [6, 55],
  [7, 68],
  [8, 82],
  [10, 100],
];
const List<List<double>> _corsiSpan = [
  [2, 10],
  [3, 25],
  [5, 55],
  [6, 68],
  [7, 82],
  [9, 100],
];
const List<List<double>> _rtAvg = [
  [180, 100],
  [220, 82],
  [260, 62],
  [300, 45],
  [350, 28],
  [450, 8],
];
const List<List<double>> _trailTime = [
  [12, 100],
  [20, 82],
  [30, 58],
  [40, 42],
  [60, 22],
  [90, 5],
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
const List<List<double>> _stroopAcc = [
  [50, 12],
  [70, 40],
  [82, 60],
  [90, 78],
  [100, 100],
];
const List<List<double>> _switchAcc = [
  [50, 12],
  [70, 40],
  [82, 60],
  [90, 78],
  [100, 100],
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

/// Maps a raw game metric onto a 0–100 score versus population norms.
///
/// [key] selects the metric's breakpoint table (`'rt-avg'`, `'nback'`,
/// `'corsi-span'`, …). For `'nback'`, [raw] must be an [NbackRaw] record; for
/// every other key it is a [num]. Unknown keys clamp-and-round the raw value.
/// Ported verbatim from `docs/design/cs-data.jsx`.
int normalize(String key, Object raw) {
  switch (key) {
    case 'nback':
      final r = raw as NbackRaw;
      final eff = r.acc + (r.n - 2) * 15;
      return jsRound(_clamp(_piece(eff.toDouble(), _nback)));
    case 'digit-span':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _digitSpan)));
    case 'corsi-span':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _corsiSpan)));
    case 'rt-avg':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _rtAvg)));
    case 'trail-time':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _trailTime)));
    case 'flanker-acc':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _flankerAcc)));
    case 'gng-acc':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _gngAcc)));
    case 'stroop-acc':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _stroopAcc)));
    case 'switch-acc':
      return jsRound(_clamp(_piece((raw as num).toDouble(), _switchAcc)));
    default:
      return jsRound(_clamp((raw as num).toDouble()));
  }
}
