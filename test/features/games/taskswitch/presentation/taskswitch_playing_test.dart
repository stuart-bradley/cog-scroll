import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_playing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskSwitchState state({
    required SwitchRule rule,
    SwitchStim stim = (shape: 0, filled: true, big: true),
    SwitchFeedback? fb,
    int? picked,
  }) => (
    phase: GamePhase.playing,
    level: 5,
    idx: 0,
    round: 20,
    rule: rule,
    stim: stim,
    picked: picked,
    fb: fb,
    summary: null,
    levelMsg: null,
  );

  Widget host(TaskSwitchState s, {void Function(int)? onPick}) => MaterialApp(
    home: Scaffold(
      body: TaskSwitchPlaying(state: s, onPick: onPick ?? (_) {}),
    ),
  );

  testWidgets('each rule banner + option labels render (incl. size)', (
    tester,
  ) async {
    const cases = {
      SwitchRule.shape: ['CIRCLE', 'SQUARE'],
      SwitchRule.fill: ['FILLED', 'HOLLOW'],
      SwitchRule.size: ['BIG', 'SMALL'],
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(host(state(rule: entry.key)));
      expect(
        find.text('JUDGE · ${entry.key.name.toUpperCase()}'),
        findsOneWidget,
      );
      expect(find.text(entry.value[0]), findsOneWidget);
      expect(find.text(entry.value[1]), findsOneWidget);
    }
  });

  testWidgets('tapping an option reports its index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      host(state(rule: SwitchRule.fill), onPick: taps.add),
    );
    await tester.tap(find.byKey(const ValueKey('switch-option-1')));
    expect(taps, [1]);
  });

  testWidgets('a hit blooms and a wrong answer shakes the stimulus', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(state(rule: SwitchRule.shape, fb: SwitchFeedback.hit)),
    );
    expect(find.byType(Bloom), findsOneWidget);

    await tester.pumpWidget(
      host(state(rule: SwitchRule.shape, fb: SwitchFeedback.wrong)),
    );
    expect(find.byType(Shake), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
