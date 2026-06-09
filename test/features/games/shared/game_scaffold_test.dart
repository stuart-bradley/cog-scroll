import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const summary = (
    value: '94%',
    caption: 'ACCURACY',
    sub: null,
    delta: null,
    levelMsg: null,
  );

  RunnerContext runner() => RunnerContext(
    index: 0,
    total: 1,
    domain: 'X',
    focus: false,
    onDone: (_) {},
    onSkip: () {},
  );

  Widget host({
    required GamePhase phase,
    RunnerContext? runner,
    RoundData? summary,
  }) => MaterialApp(
    home: GameScaffold(
      phase: phase,
      title: 'Test',
      runner: runner,
      summary: summary,
      intro: const Text('INTRO'),
      playing: const Text('PLAYING'),
    ),
  );

  testWidgets('intro phase shows the intro under a TopBar (standalone)', (
    tester,
  ) async {
    await tester.pumpWidget(host(phase: GamePhase.intro));
    expect(find.text('INTRO'), findsOneWidget);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.text('PLAYING'), findsNothing);
  });

  testWidgets('playing phase shows the play UI', (tester) async {
    await tester.pumpWidget(host(phase: GamePhase.playing));
    expect(find.text('PLAYING'), findsOneWidget);
  });

  testWidgets('round phase shows RoundEnd from the summary (standalone)', (
    tester,
  ) async {
    await tester.pumpWidget(host(phase: GamePhase.round, summary: summary));
    expect(find.byType(RoundEnd), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
  });

  testWidgets('a runner hides the TopBar', (tester) async {
    await tester.pumpWidget(host(phase: GamePhase.intro, runner: runner()));
    expect(find.byType(TopBar), findsNothing);
    expect(find.text('INTRO'), findsOneWidget);
  });

  testWidgets('under a runner the round phase shows no RoundEnd', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(phase: GamePhase.round, runner: runner(), summary: summary),
    );
    expect(find.byType(RoundEnd), findsNothing);
  });
}
