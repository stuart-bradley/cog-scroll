import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_controller.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_playing.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  late FakeGameSink sink;
  late FakeGameStore store;
  late FakeClock clock;

  setUp(() {
    sink = FakeGameSink();
    store = FakeGameStore();
    clock = FakeClock(DateTime.utc(2026));
  });

  Widget host() => ProviderScope(
    overrides: [
      gameSinkProvider.overrideWithValue(sink),
      gameStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(clock),
    ],
    child: const MaterialApp(home: StroopScreen()),
  );

  /// Reads the engine state from the running provider.
  StroopState stateOf(WidgetTester tester) {
    final element = tester.element(find.byType(StroopScreen));
    final container = ProviderScope.containerOf(element);
    return container.read(stroopControllerProvider);
  }

  /// Plays the round to its RoundEnd by tapping the correct option each trial.
  Future<void> playToEnd(WidgetTester tester) async {
    for (var guard = 0; guard < 60; guard++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      final stim = stateOf(tester).stim;
      if (stim == null) {
        await tester.pump(const Duration(milliseconds: 50));
        continue;
      }
      clock.advance(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(ValueKey('stroop-option-${stim.shape}')));
      await tester.pump(); // resolve
      await tester.pump(stroopFeedback + const Duration(milliseconds: 20));
    }
  }

  testWidgets('intro shows the word-on-plate legend and Begin', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('BEGIN'), findsOneWidget);
    // The legend draws a shape under a legible word plate.
    expect(find.byType(StroopWordPlate), findsOneWidget);
  });

  testWidgets('plays a round to a RoundEnd and records interference', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    expect(find.byType(StroopPlaying), findsOneWidget);

    await playToEnd(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(find.text('INTERFERENCE'), findsOneWidget); // caption is uppercased
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Attention & Inhibition');
    expect(store.values[CsStoreKeys.stroopInterference], isNotNull);
  });

  testWidgets('a correct tap blooms with the stimulus shape still visible', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    final stim = stateOf(tester).stim!;
    clock.advance(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(ValueKey('stroop-option-${stim.shape}')));
    await tester.pump();

    final bloom = find.byType(Bloom);
    expect(bloom, findsOneWidget);
    // The drawn shape stays visible inside the bloom for the whole motion.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(of: bloom, matching: find.byType(Shape)),
      findsWidgets,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('a wrong tap shakes the stimulus', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    final stim = stateOf(tester).stim!;
    final wrong = stim.options.firstWhere((o) => o != stim.shape);
    clock.advance(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(ValueKey('stroop-option-$wrong')));
    await tester.pump();

    expect(find.byType(Shake), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('no runner: TopBar is always present', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(TopBar), findsOneWidget);
  });
}
