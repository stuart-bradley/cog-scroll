import 'package:cogscroll/core/analytics/analytics_service.dart';
import 'package:cogscroll/core/analytics/app_database_provider.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_providers.g.dart';

/// Provides the app-wide [AnalyticsService] over the Drift DAO and `Clock`.
@Riverpod(keepAlive: true)
AnalyticsService analytics(Ref ref) => AnalyticsService(
  ref.watch(appDatabaseProvider).analyticsDao,
  ref.watch(clockProvider),
);

/// Current EMA score per domain (null where unmeasured).
@riverpod
Future<Map<String, int?>> domainScores(Ref ref) =>
    ref.watch(analyticsProvider).domainScores();

/// First measured (baseline) score per domain (null where unmeasured).
@riverpod
Future<Map<String, int?>> domainBaselines(Ref ref) =>
    ref.watch(analyticsProvider).baselineScores();

/// Normalized score history (0–100, oldest first) for a single [domain].
///
/// Backs the dashboard sparklines: [DomainTrend] carries only the trend
/// classification, not the underlying points.
@riverpod
Future<List<int>> domainHistory(Ref ref, String domain) =>
    ref.watch(analyticsProvider).domainHistory(domain);

/// Trend classification for a single [domain].
///
/// Derived from the cached [domainHistoryProvider] read so a row that shows
/// both the trend and the sparkline hits the database once, not twice.
@riverpod
Future<DomainTrend> domainTrend(Ref ref, String domain) async =>
    classifyTrend(await ref.watch(domainHistoryProvider(domain).future));
