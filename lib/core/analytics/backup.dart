import 'dart:convert';

import 'package:cogscroll/core/analytics/analytics_dao.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';

/// The envelope `data` key under which the Drift analytics ride, mirroring the
/// prototype's single `domains` blob.
const _domainsKey = 'domains';

/// Builds the export envelope: the prototype `domains` analytics blob (rebuilt
/// from Drift) plus every [CsStore] key, wrapped with app/version/[exportedAt]
/// metadata. Wire-compatible with the React prototype's export files.
Future<Map<String, dynamic>> snapshot(
  AnalyticsDao dao,
  CsStore store,
  DateTime exportedAt,
) async {
  final data = <String, dynamic>{};
  for (final key in store.keys()) {
    data[key] = store.getJson<Object>(key);
  }
  data[_domainsKey] = await _readDomains(dao);
  return {
    'app': 'CogScroll',
    'version': 1,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'data': data,
  };
}

/// Pretty-prints [snapshot] as the JSON written to a backup file.
Future<String> exportBackup(
  AnalyticsDao dao,
  CsStore store,
  DateTime exportedAt,
) async => const JsonEncoder.withIndent(
  '  ',
).convert(await snapshot(dao, store, exportedAt));

/// Restores a backup [text] — either a full envelope (`{data: {...}}`) or a raw
/// key/value map. Drift analytics ride in the `domains` key (replacing all
/// existing analytics); every other key is written to [store]. Returns the
/// number of top-level keys restored, or throws [FormatException] on a
/// malformed payload.
Future<int> importBackup(String text, AnalyticsDao dao, CsStore store) async {
  final parsed = jsonDecode(text);
  final data = parsed is Map && parsed['data'] != null
      ? parsed['data']
      : parsed;
  if (data is! Map) throw const FormatException('Unrecognised backup file');

  for (final entry in data.entries) {
    final key = entry.key as String;
    if (key == _domainsKey) {
      await dao.restore(_parseDomains(entry.value));
    } else {
      await store.setJson(key, entry.value);
    }
  }
  return data.length;
}

/// Wipes analytics for a baseline redo (SPEC §4.4): clears both Drift tables
/// and the per-game prefs plus `onboarded`. Leaves trial, purchase, reminders,
/// `baselinePrompted`, and the current session untouched.
Future<void> clearAnalytics(AnalyticsDao dao, CsStore store) async {
  await dao.clearAll();
  for (final key in [...CsStoreKeys.perfKeys, CsStoreKeys.onboarded]) {
    await store.remove(key);
  }
}

/// Serializes Drift analytics into the prototype's `{domain: {score, history}}`
/// shape, with history timestamps as ms-since-epoch.
Future<Map<String, dynamic>> _readDomains(AnalyticsDao dao) async {
  final scores = await dao.readScores();
  final out = <String, dynamic>{};
  for (final domain in scores.keys) {
    final rows = await dao.readHistoryRows(domain);
    out[domain] = {
      'score': scores[domain],
      'history': [
        for (final r in rows)
          {'t': r.at.toUtc().millisecondsSinceEpoch, 'score': r.score},
      ],
    };
  }
  return out;
}

/// Parses the `domains` blob back into the DAO restore shape, tolerating
/// missing/typeless fields rather than throwing on a partial blob.
Map<String, DomainBackup> _parseDomains(Object? blob) {
  if (blob is! Map) return const {};
  final out = <String, DomainBackup>{};
  blob.forEach((domain, rec) {
    if (rec is! Map) return;
    final score = (rec['score'] as num?)?.toInt();
    final rawHistory = rec['history'];
    final history = <HistoryEntry>[
      if (rawHistory is List)
        for (final h in rawHistory)
          if (h is Map)
            (
              at: DateTime.fromMillisecondsSinceEpoch(
                (h['t'] as num).toInt(),
                isUtc: true,
              ),
              score: (h['score'] as num).toInt(),
            ),
    ];
    out[domain as String] = (score: score, history: history);
  });
  return out;
}
