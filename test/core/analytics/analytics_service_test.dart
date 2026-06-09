import 'package:cogscroll/core/analytics/analytics_service.dart';
import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AnalyticsService svc;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 6, 9, 12));
    svc = AnalyticsService(db.analyticsDao, clock);
  });
  tearDown(() => db.close());

  test('recordResult ignores unknown domains', () async {
    await svc.recordResult('Not A Domain', 80);
    expect(await svc.hasData(), isFalse);
  });

  test('domainScores covers every domain, null when unmeasured', () async {
    await svc.recordResult(Domains.workingMemory, 70);
    final scores = await svc.domainScores();
    expect(scores[Domains.workingMemory], 70);
    expect(scores[Domains.processingSpeed], isNull);
    expect(scores.length, Domains.all.length);
  });

  test('baselineScores is the first measured value per domain', () async {
    await svc.recordResult(Domains.spatialReasoning, 40);
    await svc.recordResult(Domains.spatialReasoning, 90);
    final base = await svc.baselineScores();
    expect(base[Domains.spatialReasoning], 40);
    expect(base[Domains.mentalFlexibility], isNull);
  });

  test('uses the injected clock for timestamps', () async {
    clock.setTime(DateTime.utc(2030));
    await svc.recordResult(Domains.processingSpeed, 50);
    final rows = await db.analyticsDao.readHistoryRows(Domains.processingSpeed);
    expect(rows.single.at.toUtc(), DateTime.utc(2030));
  });

  group('domainTrend', () {
    Future<void> record(List<int> scores) async {
      for (final s in scores) {
        await svc.recordResult(Domains.workingMemory, s);
      }
    }

    test('returns none with fewer than 3 results', () async {
      await record([50, 60]);
      final t = await svc.domainTrend(Domains.workingMemory);
      expect(t.state, TrendState.none);
      expect(t.n, 2);
    });

    test('improving when recent beats earlier by >= 4 (n=3, k=1)', () async {
      // earlier = [50, 52], recent = [56]; delta = round(56 - 51) = 5.
      await record([50, 52, 56]);
      final t = await svc.domainTrend(Domains.workingMemory);
      expect(t.state, TrendState.improving);
      expect(t.delta, 5);
    });

    test('stable when the gap is under 4 (delta 3)', () async {
      // earlier = [50, 50], recent = [53]; delta = 3.
      await record([50, 50, 53]);
      expect(
        (await svc.domainTrend(Domains.workingMemory)).state,
        TrendState.stable,
      );
    });

    test('declining when earlier beats recent by >= 4', () async {
      // earlier = [60, 60], recent = [55]; delta = -5.
      await record([60, 60, 55]);
      final t = await svc.domainTrend(Domains.workingMemory);
      expect(t.state, TrendState.declining);
      expect(t.delta, -5);
    });

    test('exact +/-4 boundary: +4 improving, -4 declining', () async {
      await record([50, 50, 54]); // delta +4
      expect(
        (await svc.domainTrend(Domains.workingMemory)).state,
        TrendState.improving,
      );
      // Separate domain for the -4 case (delta = round(50 - 54)).
      await svc.recordResult(Domains.processingSpeed, 54);
      await svc.recordResult(Domains.processingSpeed, 54);
      await svc.recordResult(Domains.processingSpeed, 50);
      expect(
        (await svc.domainTrend(Domains.processingSpeed)).state,
        TrendState.declining,
      );
    });

    test('uses k=3 recent vs earlier for longer histories (n=6)', () async {
      // earlier = [10,20,30] (avg 20), recent = [80,90,100] (avg 90) → +70.
      await record([10, 20, 30, 80, 90, 100]);
      final t = await svc.domainTrend(Domains.workingMemory);
      expect(t.n, 6);
      expect(t.state, TrendState.improving);
      expect(t.delta, 70);
    });
  });
}
