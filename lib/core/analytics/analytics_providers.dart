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

/// Trend classification for a single [domain].
@riverpod
Future<DomainTrend> domainTrend(Ref ref, String domain) =>
    ref.watch(analyticsProvider).domainTrend(domain);
