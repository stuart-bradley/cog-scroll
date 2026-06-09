import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReactionState state(ReactionStage stage, {int? ms}) => (
    phase: GamePhase.playing,
    stage: stage,
    ms: ms,
    trial: 0,
    total: 5,
    summary: null,
  );

  Widget host(ReactionStage stage, {int? ms}) => MaterialApp(
    home: Scaffold(
      body: ReactionPlaying(
        state: state(stage, ms: ms),
        onTap: () {},
      ),
    ),
  );

  testWidgets('wait stage shows the wait hint', (tester) async {
    await tester.pumpWidget(host(ReactionStage.wait));
    expect(find.text('WAIT FOR IT…'), findsOneWidget);
  });

  testWidgets('ready stage pops the stimulus in', (tester) async {
    await tester.pumpWidget(host(ReactionStage.ready));
    expect(find.byType(Pop), findsOneWidget);
    expect(find.byType(Shape), findsOneWidget);
  });

  testWidgets('the stimulus stays visible through the pop entrance', (
    tester,
  ) async {
    await tester.pumpWidget(host(ReactionStage.ready));
    // Tick across the whole pop window — the stimulus never blanks.
    for (var i = 0; i < 5; i++) {
      expect(find.byType(Shape), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byType(Shape), findsOneWidget);
  });

  testWidgets('result stage shows the measured time', (tester) async {
    await tester.pumpWidget(host(ReactionStage.result, ms: 247));
    expect(find.text('247'), findsOneWidget);
    expect(find.text('MS'), findsOneWidget);
  });

  testWidgets('too-soon stage shakes an outline with a warning', (
    tester,
  ) async {
    await tester.pumpWidget(host(ReactionStage.tooSoon));
    expect(find.byType(Shake), findsOneWidget);
    expect(find.text('TOO SOON'), findsOneWidget);
  });
}
