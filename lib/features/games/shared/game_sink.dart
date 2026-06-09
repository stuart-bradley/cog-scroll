import 'dart:async';

import 'package:cogscroll/core/analytics/analytics_providers.dart';
import 'package:cogscroll/core/analytics/analytics_service.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/timers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_sink.g.dart';

/// [GameStore] over [CsStore]: synchronous reads, fire-and-forget JSON writes
/// (matching the prototype's synchronous `CS.store.set`).
class CsGameStore implements GameStore {
  /// Wraps an eager [CsStore].
  const CsGameStore(this._store);

  final CsStore _store;

  @override
  int? getInt(String key) => _store.getInt(key);

  @override
  double? getDouble(String key) => _store.getDouble(key);

  @override
  String? getString(String key) => _store.getString(key);

  @override
  void setInt(String key, int value) => unawaited(_store.setJson(key, value));

  @override
  void setDouble(String key, double value) =>
      unawaited(_store.setJson(key, value));

  @override
  void setString(String key, String value) =>
      unawaited(_store.setJson(key, value));
}

/// [GameSink] over [AnalyticsService].
class GameSinkImpl implements GameSink {
  /// Wraps the app [AnalyticsService].
  const GameSinkImpl(this._analytics);

  final AnalyticsService _analytics;

  @override
  Future<void> recordResult(String domain, int score) =>
      _analytics.recordResult(domain, score);
}

/// Synchronous per-game store for engines.
@Riverpod(keepAlive: true)
GameStore gameStore(Ref ref) => CsGameStore(ref.watch(csStoreProvider));

/// Analytics sink for engines.
@Riverpod(keepAlive: true)
GameSink gameSink(Ref ref) => GameSinkImpl(ref.watch(analyticsProvider));

/// Timer factory for engines (real in app; fake-driven under `fakeAsync`).
@Riverpod(keepAlive: true)
Timers timers(Ref ref) => const RealTimers();
