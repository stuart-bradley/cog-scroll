import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_controller.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_playing.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_screen.dart';
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

  Widget host() => ProviderScope(
    overrides: [
      gameSinkProvider.overrideWithValue(sink),
      gameStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
    ],
    child: const MaterialApp(home: TaskSwitchScreen()),
  );

  TaskSwitchState stateOf(WidgetTester tester) {
    final element = tester.element(find.byType(TaskSwitchScreen));
    final container = ProviderScope.containerOf(element);
    return container.read(taskSwitchControllerProvider);
  }

  /// Plays the round to its RoundEnd by judging the active rule correctly. At
  /// each trial [onTrial] is invoked with the live rule (for contract checks).
  Future<void> playToEnd(
    WidgetTester tester, {
    void Function(SwitchRule rule)? onTrial,
  }) async {
    for (var guard = 0; guard < 80; guard++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      final st = stateOf(tester);
      final stim = st.stim;
      if (stim == null) {
        await tester.pump(const Duration(milliseconds: 50));
        continue;
      }
      onTrial?.call(st.rule);
      final choice = switchCorrectChoice(st.rule, stim);
      await tester.tap(find.byKey(ValueKey('switch-option-$choice')));
      await tester.pump(); // resolve
      await tester.pump(taskSwitchFeedback + const Duration(milliseconds: 20));
    }
  }

  testWidgets('intro shows a shape legend and Begin', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('BEGIN'), findsOneWidget);
    expect(find.byType(Shape), findsOneWidget);
  });

  testWidgets('the banner and option labels match the active rule', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    final rule = stateOf(tester).rule;
    expect(find.text('JUDGE · ${rule.name.toUpperCase()}'), findsOneWidget);
    final labels = switchOptionLabels(rule);
    expect(find.text(labels[0].toUpperCase()), findsOneWidget);
    expect(find.text(labels[1].toUpperCase()), findsOneWidget);
  });

  testWidgets('plays a round to a RoundEnd and records accuracy', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    expect(find.byType(TaskSwitchPlaying), findsOneWidget);

    await playToEnd(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(find.text('100%'), findsOneWidget); // all judged correctly
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Mental Flexibility');
    expect(store.values[CsStoreKeys.switchAcc], 100);
  });

  testWidgets('the banner reflects the active rule throughout an L5 round', (
    tester,
  ) async {
    // Deterministic: rather than asserting which rules the unseeded RNG draws,
    // verify the banner matches whatever rule is active on every trial (the
    // rendering contract). Full three-rule coverage lives in the seeded engine
    // test; the size-banner UI is covered by the playing-widget test.
    store.setInt(CsStoreKeys.switchLevel, 5);
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    await playToEnd(
      tester,
      onTrial: (rule) {
        expect(
          find.text('JUDGE · ${rule.name.toUpperCase()}'),
          findsOneWidget,
          reason: 'banner should match the active rule',
        );
      },
    );
  });

  testWidgets('a correct judgement blooms the stimulus', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    final st = stateOf(tester);
    final choice = switchCorrectChoice(st.rule, st.stim!);
    await tester.tap(find.byKey(ValueKey('switch-option-$choice')));
    await tester.pump();

    final bloom = find.byType(Bloom);
    expect(bloom, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(of: bloom, matching: find.byType(Shape)),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('a wrong judgement shakes the stimulus', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('BEGIN'));
    await tester.pump();

    final st = stateOf(tester);
    final wrong = 1 - switchCorrectChoice(st.rule, st.stim!);
    await tester.tap(find.byKey(ValueKey('switch-option-$wrong')));
    await tester.pump();

    expect(find.byType(Shake), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('no runner: TopBar is always present', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(TopBar), findsOneWidget);
  });
}
