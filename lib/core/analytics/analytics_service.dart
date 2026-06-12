import 'package:cogscroll/core/analytics/analytics_dao.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/time/clock.dart';

/// Improving/declining threshold (points) for [classifyTrend].
const _stable = 4;

/// Classifies a domain's [history] (oldest first) into a [DomainTrend] by
/// averaging the most recent results against the earlier ones. Needs at least
/// three results; "up" already means better because normalization inverts
/// time-based metrics. Pure, so callers can classify a history they already
/// hold without a second read.
DomainTrend classifyTrend(List<int> history) {
  final n = history.length;
  if (n < 3) return (state: TrendState.none, delta: 0, n: n);
  final half = n ~/ 2;
  final k = half < 3 ? half : 3;
  final recent = history.sublist(n - k);
  final earlier = history.sublist(0, n - k);
  final delta = jsRound(_avg(recent) - _avg(earlier));
  final state = delta >= _stable
      ? TrendState.improving
      : delta <= -_stable
      ? TrendState.declining
      : TrendState.stable;
  return (state: state, delta: delta, n: n);
}

double _avg(List<int> xs) => xs.fold<int>(0, (a, b) => a + b) / xs.length;

/// Reads and writes the per-domain analytics that feed the dashboard and the
/// adaptive session picker. Wraps [AnalyticsDao] and timestamps results via the
/// injected [Clock]. Behaviour is ported from `docs/design/cs-data.jsx`.
class AnalyticsService {
  /// Creates an [AnalyticsService] over [_dao], stamping results with [_clock].
  AnalyticsService(this._dao, this._clock);

  final AnalyticsDao _dao;
  final Clock _clock;

  /// Records a normalized [score] (0–100) against [domain]. Unknown domains are
  /// ignored (mirrors the prototype's guard).
  Future<void> recordResult(String domain, int score) async {
    if (!Domains.all.contains(domain)) return;
    await _dao.recordResult(domain, score, _clock.now());
  }

  /// Every domain's current EMA score, null where not yet measured.
  Future<Map<String, int?>> domainScores() async {
    final measured = await _dao.readScores();
    return {for (final d in Domains.all) d: measured[d]};
  }

  /// The first measured (baseline) score per domain, null where unmeasured.
  Future<Map<String, int?>> baselineScores() async {
    final base = await _dao.readBaselines();
    return {for (final d in Domains.all) d: base[d]};
  }

  /// The normalized score history for [domain], oldest first.
  Future<List<int>> domainHistory(String domain) => _dao.readHistory(domain);

  /// Whether any domain has at least one measured score.
  Future<bool> hasData() async => (await _dao.readScores()).isNotEmpty;

  /// Classifies [domain]'s trend from its score history (see [classifyTrend]).
  Future<DomainTrend> domainTrend(String domain) async =>
      classifyTrend(await _dao.readHistory(domain));
}
