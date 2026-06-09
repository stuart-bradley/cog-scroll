import 'package:cogscroll/core/analytics/analytics_dao.dart';
import 'package:cogscroll/core/analytics/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The on-device analytics database (Drift).
///
/// Holds only analytics that benefit from history/queries: [DomainScores] (EMA
/// per domain) and [ScoreHistory] (capped at 60 rows per domain). All other
/// persisted state lives in `shared_preferences` via `CsStore`.
@DriftDatabase(tables: [DomainScores, ScoreHistory], daos: [AnalyticsDao])
class AppDatabase extends _$AppDatabase {
  /// Opens the app database on disk, or wraps a provided [executor] (tests pass
  /// an in-memory `NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cogscroll'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
