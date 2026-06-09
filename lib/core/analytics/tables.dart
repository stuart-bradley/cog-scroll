import 'package:drift/drift.dart';

/// Per-domain rolling score (EMA), 0–100. One row per measured domain.
class DomainScores extends Table {
  /// The cognitive domain name (primary key).
  TextColumn get domain => text()();

  /// The EMA score, 0–100 (always whole-valued).
  RealColumn get score => real()();

  @override
  Set<Column<Object>> get primaryKey => {domain};
}

/// Append-only log of normalized results, pruned to the most recent 60 rows per
/// domain. Ascending [id] is chronological order; the oldest surviving row per
/// domain is the baseline ghost shown on the radar.
@TableIndex(name: 'score_history_domain_id', columns: {#domain, #id})
class ScoreHistory extends Table {
  /// Auto-incrementing surrogate key; ascending id == insertion order.
  IntColumn get id => integer().autoIncrement()();

  /// The cognitive domain name.
  TextColumn get domain => text()();

  /// When the result was recorded.
  DateTimeColumn get recordedAt => dateTime()();

  /// The normalized score, 0–100.
  RealColumn get score => real()();
}
