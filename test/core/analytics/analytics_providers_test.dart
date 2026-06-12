import 'package:cogscroll/core/analytics/analytics_providers.dart';
import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/app_database_provider.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('domainScoresProvider covers all domains, null unmeasured', () async {
    await container
        .read(analyticsProvider)
        .recordResult(Domains.workingMemory, 70);
    final scores = await container.read(domainScoresProvider.future);
    expect(scores[Domains.workingMemory], 70);
    expect(scores[Domains.spatialReasoning], isNull);
    expect(scores.length, Domains.all.length);
  });

  test('domainTrendProvider returns none before 3 results', () async {
    final t = await container.read(
      domainTrendProvider(Domains.workingMemory).future,
    );
    expect(t.state, TrendState.none);
  });

  test('domainHistoryProvider returns scores oldest-first', () async {
    final analytics = container.read(analyticsProvider);
    await analytics.recordResult(Domains.workingMemory, 40);
    await analytics.recordResult(Domains.workingMemory, 60);
    await analytics.recordResult(Domains.workingMemory, 80);

    final history = await container.read(
      domainHistoryProvider(Domains.workingMemory).future,
    );
    expect(history, [40, 60, 80]);
  });

  test('domainHistoryProvider is empty for an unmeasured domain', () async {
    final history = await container.read(
      domainHistoryProvider(Domains.spatialReasoning).future,
    );
    expect(history, isEmpty);
  });
}
