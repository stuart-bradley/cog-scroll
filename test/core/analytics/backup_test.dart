import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/backup.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CsStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    return CsStore(await SharedPreferences.getInstance());
  }

  test('export then import round-trips analytics and prefs', () async {
    final db1 = AppDatabase(NativeDatabase.memory());
    final store = await freshStore();
    await store.setJson(CsStoreKeys.nbackN, 3);
    await store.setJson(CsStoreKeys.onboarded, true);
    await db1.analyticsDao.recordResult(
      'Working Memory',
      70,
      DateTime.utc(2026),
    );
    await db1.analyticsDao.recordResult(
      'Working Memory',
      90,
      DateTime.utc(2026, 2),
    );

    final json = await exportBackup(
      db1.analyticsDao,
      store,
      DateTime.utc(2026, 6, 9, 12),
    );
    await db1.close();

    // Simulate a clean target device: drop the prefs, use a fresh in-memory db.
    await store.remove(CsStoreKeys.nbackN);
    await store.remove(CsStoreKeys.onboarded);
    final db2 = AppDatabase(NativeDatabase.memory());

    final count = await importBackup(json, db2.analyticsDao, store);

    expect(store.getInt(CsStoreKeys.nbackN), 3);
    expect(store.getBool(CsStoreKeys.onboarded), true);
    expect(await db2.analyticsDao.readScores(), {'Working Memory': 78});
    expect(await db2.analyticsDao.readHistory('Working Memory'), [70, 90]);
    expect((await db2.analyticsDao.readBaselines())['Working Memory'], 70);
    expect(count, 3); // nback-n, onboarded, domains
    await db2.close();
  });

  test('import accepts a raw map without the {data} wrapper', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = await freshStore();
    final count = await importBackup('{"nback-n": 5}', db.analyticsDao, store);
    expect(store.getInt(CsStoreKeys.nbackN), 5);
    expect(count, 1);
    expect(await db.analyticsDao.readScores(), isEmpty); // no domains key
    await db.close();
  });

  test('malformed payloads throw FormatException', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = await freshStore();
    await expectLater(
      importBackup('not json', db.analyticsDao, store),
      throwsFormatException,
    );
    await expectLater(
      importBackup('5', db.analyticsDao, store),
      throwsFormatException,
    );
    await expectLater(
      importBackup('{"data": 42}', db.analyticsDao, store),
      throwsFormatException,
    );
    await db.close();
  });

  test('clearAnalytics clears exactly the redo-baseline set', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = await freshStore();
    await db.analyticsDao.recordResult(
      'Working Memory',
      70,
      DateTime.utc(2026),
    );
    for (final k in CsStoreKeys.perfKeys) {
      await store.setJson(k, 1);
    }
    await store.setJson(CsStoreKeys.onboarded, true);
    // Keys that must survive a baseline redo.
    await store.setJson(CsStoreKeys.trialStart, 123);
    await store.setJson(CsStoreKeys.purchasedCache, true);
    await store.setJson(CsStoreKeys.notify, true);
    await store.setJson(CsStoreKeys.notifyTime, {'h': 9, 'm': 0});
    await store.setJson(CsStoreKeys.baselinePrompted, true);
    await store.setJson(CsStoreKeys.session, {'date': 'today'});

    await clearAnalytics(db.analyticsDao, store);

    expect(await db.analyticsDao.readScores(), isEmpty);
    for (final k in CsStoreKeys.perfKeys) {
      expect(store.getInt(k), isNull, reason: k);
    }
    expect(store.getBool(CsStoreKeys.onboarded), isNull);
    // Preserved:
    expect(store.getInt(CsStoreKeys.trialStart), 123);
    expect(store.getBool(CsStoreKeys.purchasedCache), true);
    expect(store.getBool(CsStoreKeys.notify), true);
    expect(
      store.getJson<Map<String, dynamic>>(CsStoreKeys.notifyTime),
      isNotNull,
    );
    expect(store.getBool(CsStoreKeys.baselinePrompted), true);
    expect(store.getJson<Map<String, dynamic>>(CsStoreKeys.session), isNotNull);
    await db.close();
  });
}
