import 'package:cogscroll/core/analytics/analytics_dao.dart';
import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;
  final t = DateTime.utc(2026, 6, 9, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.analyticsDao;
  });
  tearDown(() => db.close());

  group('recordResult EMA', () {
    test('seeds the score on the first result', () async {
      await dao.recordResult('Working Memory', 70, t);
      expect(await dao.readScores(), {'Working Memory': 70});
    });

    test('blends round(old*0.6 + new*0.4) after seeding', () async {
      await dao.recordResult('Working Memory', 70, t);
      await dao.recordResult('Working Memory', 90, t);
      // round(70*0.6 + 90*0.4) = round(42 + 36) = 78
      expect((await dao.readScores())['Working Memory'], 78);
    });
  });

  group('history', () {
    test('readHistory returns scores oldest-first', () async {
      for (final s in [10, 20, 30]) {
        await dao.recordResult('Processing Speed', s, t);
      }
      expect(await dao.readHistory('Processing Speed'), [10, 20, 30]);
    });

    test('prunes to the most recent 60 per domain', () async {
      for (var i = 1; i <= 65; i++) {
        await dao.recordResult('Spatial Reasoning', i, t);
      }
      final h = await dao.readHistory('Spatial Reasoning');
      expect(h.length, 60);
      expect(h.first, 6); // values 1..5 pruned
      expect(h.last, 65);
    });

    test('baseline ghost is the first row before any prune', () async {
      await dao.recordResult('Mental Flexibility', 42, t);
      await dao.recordResult('Mental Flexibility', 99, t);
      expect((await dao.readBaselines())['Mental Flexibility'], 42);
    });

    test('baseline ghost drifts to oldest survivor after prune', () async {
      for (var i = 1; i <= 65; i++) {
        await dao.recordResult('Spatial Reasoning', i, t);
      }
      expect((await dao.readBaselines())['Spatial Reasoning'], 6);
    });
  });

  test('clearAll empties both tables', () async {
    await dao.recordResult('Working Memory', 70, t);
    await dao.clearAll();
    expect(await dao.readScores(), isEmpty);
    expect(await dao.readHistory('Working Memory'), isEmpty);
    expect(await dao.readBaselines(), isEmpty);
  });

  group('backup primitives', () {
    test('readHistoryRows preserves timestamps oldest-first', () async {
      await dao.recordResult('Working Memory', 70, DateTime.utc(2026));
      await dao.recordResult('Working Memory', 80, DateTime.utc(2026, 2));
      final rows = await dao.readHistoryRows('Working Memory');
      expect(rows.map((r) => r.score).toList(), [70, 80]);
      // Drift returns DateTimes in local time; compare the instant.
      expect(rows.first.at.toUtc(), DateTime.utc(2026));
    });

    test('restore replaces analytics with the given entries', () async {
      await dao.recordResult('Working Memory', 5, t); // wiped by restore
      await dao.restore({
        'Processing Speed': (
          score: 64,
          history: [
            (at: DateTime.utc(2026), score: 50),
            (at: DateTime.utc(2026, 2), score: 70),
          ],
        ),
      });
      expect(await dao.readScores(), {'Processing Speed': 64});
      expect(await dao.readHistory('Processing Speed'), [50, 70]);
      expect(await dao.readHistory('Working Memory'), isEmpty);
    });
  });
}
