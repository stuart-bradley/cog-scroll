import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/tables.dart';
import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:drift/drift.dart';

part 'analytics_dao.g.dart';

/// One history row: when a normalized result was recorded and its score.
typedef HistoryEntry = ({DateTime at, int score});

/// One domain's analytics for backup restore: its EMA `score` (null if
/// unmeasured) and full `history`, oldest first.
typedef DomainBackup = ({int? score, List<HistoryEntry> history});

/// Data access for the analytics tables: EMA upsert, 60-cap history pruning,
/// baseline-ghost derivation, and the bulk read/restore that backup uses.
@DriftAccessor(tables: [DomainScores, ScoreHistory])
class AnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$AnalyticsDaoMixin {
  /// Creates an [AnalyticsDao] over [attachedDatabase].
  AnalyticsDao(super.attachedDatabase);

  /// History rows kept per domain; older rows are pruned after each insert.
  static const historyCap = 60;

  /// Records a normalized [score] (0–100) for [domain] at [at]: appends a
  /// history row (pruned to the most recent [historyCap] for that domain) and
  /// updates the EMA score — seeded on the first result, then
  /// `round(old * 0.6 + new * 0.4)`.
  Future<void> recordResult(String domain, int score, DateTime at) {
    return transaction(() async {
      await into(scoreHistory).insert(
        ScoreHistoryCompanion.insert(
          domain: domain,
          recordedAt: at,
          score: score.toDouble(),
        ),
      );
      await _prune(domain);

      final existing = await (select(
        domainScores,
      )..where((t) => t.domain.equals(domain))).getSingleOrNull();
      final next = existing == null
          ? score
          : jsRound(existing.score * 0.6 + score * 0.4);
      await into(domainScores).insertOnConflictUpdate(
        DomainScoresCompanion.insert(domain: domain, score: next.toDouble()),
      );
    });
  }

  /// Deletes all but the most recent [historyCap] rows for [domain].
  Future<void> _prune(String domain) async {
    final keepIds =
        await (selectOnly(scoreHistory)
              ..addColumns([scoreHistory.id])
              ..where(scoreHistory.domain.equals(domain))
              ..orderBy([OrderingTerm.desc(scoreHistory.id)])
              ..limit(historyCap))
            .map((row) => row.read(scoreHistory.id)!)
            .get();
    await (delete(
      scoreHistory,
    )..where((t) => t.domain.equals(domain) & t.id.isNotIn(keepIds))).go();
  }

  /// Every measured domain's EMA score as a `{domain: score}` map.
  Future<Map<String, int>> readScores() async {
    final rows = await select(domainScores).get();
    return {for (final r in rows) r.domain: jsRound(r.score)};
  }

  /// The normalized score history for [domain], oldest first.
  Future<List<int>> readHistory(String domain) async {
    final rows =
        await (select(scoreHistory)
              ..where((t) => t.domain.equals(domain))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return [for (final r in rows) jsRound(r.score)];
  }

  /// Full history rows (with timestamps) for [domain], oldest first — for
  /// backup export.
  Future<List<HistoryEntry>> readHistoryRows(String domain) async {
    final rows =
        await (select(scoreHistory)
              ..where((t) => t.domain.equals(domain))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return [
      for (final r in rows) (at: r.recordedAt, score: jsRound(r.score)),
    ];
  }

  /// The first (oldest surviving) score per domain — the baseline ghost.
  Future<Map<String, int>> readBaselines() async {
    final rows = await (select(
      scoreHistory,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final out = <String, int>{};
    for (final r in rows) {
      out.putIfAbsent(r.domain, () => jsRound(r.score));
    }
    return out;
  }

  /// Empties both analytics tables (used by a baseline redo and by import).
  Future<void> clearAll() async {
    await delete(scoreHistory).go();
    await delete(domainScores).go();
  }

  /// Replaces all analytics with [entries]: clears both tables, then inserts
  /// each domain's history rows (preserving timestamps) and EMA score. Used by
  /// backup import.
  Future<void> restore(Map<String, DomainBackup> entries) {
    return transaction(() async {
      await clearAll();
      for (final entry in entries.entries) {
        final domain = entry.key;
        for (final h in entry.value.history) {
          await into(scoreHistory).insert(
            ScoreHistoryCompanion.insert(
              domain: domain,
              recordedAt: h.at,
              score: h.score.toDouble(),
            ),
          );
        }
        final score = entry.value.score;
        if (score != null) {
          await into(domainScores).insert(
            DomainScoresCompanion.insert(
              domain: domain,
              score: score.toDouble(),
            ),
          );
        }
      }
    });
  }
}
