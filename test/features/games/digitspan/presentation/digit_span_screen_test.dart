import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_playing.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_screen.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  late FakeGameSink sink;
  late FakeGameStore store;

  setUp(() {
    sink = FakeGameSink();
    store = FakeGameStore();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [
      gameSinkProvider.overrideWithValue(sink),
      gameStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
    ],
    child: MaterialApp(home: child),
  );

  /// Plays each trial by tapping the "1" key enough times to fill any span (the
  /// engine ignores pads once the trial resolves). The recalled sequence is
  /// almost never the real one, so trials resolve and the round advances.
  Future<void> drive(WidgetTester tester, {int maxTrials = 20}) async {
    for (var t = 0; t < maxTrials; t++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      if (find.byType(DigitSpanPlaying).evaluate().isEmpty) break;
      await tester.pump(const Duration(seconds: 9)); // through show → recall
      for (var k = 0; k < 8; k++) {
        final key = find.byKey(const ValueKey('digit-key-1'));
        if (key.evaluate().isEmpty) break;
        await tester.tap(key);
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 1000)); // past feedback
    }
  }

  testWidgets('forward: plays a round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DigitSpanScreen(mode: DigitSpanMode.forward)),
    );
    expect(find.text('FORWARD ORDER'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drive(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls.single.domain, 'Working Memory');
    expect(store.values[CsStoreKeys.digitSpanFwd], isNotNull);
  });

  testWidgets('backward: plays a round and persists the backward key', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DigitSpanScreen(mode: DigitSpanMode.backward)),
    );
    expect(find.text('BACKWARD ORDER'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drive(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls.single.domain, 'Working Memory');
    expect(store.values[CsStoreKeys.digitSpanBwd], isNotNull);
    expect(store.values[CsStoreKeys.digitSpanFwd], isNull);
  });
}
