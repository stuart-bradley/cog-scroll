import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/motion/surge.dart';
import 'package:cogscroll/core/ui_kit/countdown.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_arrow.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlankerState state({
    FlankerFeedback? fb,
    int level = 1,
    FlankerDir dir = FlankerDir.right,
  }) => (
    phase: GamePhase.playing,
    level: level,
    round: 20,
    idx: 0,
    dir: dir,
    fb: fb,
    summary: null,
    levelMsg: null,
  );

  Widget host(FlankerState s) => MaterialApp(
    home: Scaffold(
      body: FlankerPlaying(state: s, onRespond: (_) {}),
    ),
  );

  testWidgets('an unresolved trial shows the countdown and the arrow row', (
    tester,
  ) async {
    await tester.pumpWidget(host(state()));
    expect(find.byType(Countdown), findsOneWidget);
    expect(find.byType(Surge), findsNothing);
    expect(find.byType(Shake), findsNothing);
    // L1: one flanker each side + target (3) + two response buttons (2) = 5.
    expect(find.byType(FlankerArrow), findsNWidgets(5));
  });

  testWidgets('a correct answer surges the arrow row (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: FlankerFeedback.hit)));
    expect(find.byType(Surge), findsOneWidget);
    expect(find.byType(FlankerArrow), findsWidgets); // stays in the tree
  });

  testWidgets('a wrong answer shakes the arrow row (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: FlankerFeedback.wrong)));
    expect(find.byType(Shake), findsOneWidget);
    expect(find.byType(FlankerArrow), findsWidgets);
  });

  testWidgets('a higher level draws two flankers per side', (tester) async {
    await tester.pumpWidget(host(state(level: 3)));
    // L3: two flankers each side + target (5) + two buttons (2) = 7.
    expect(find.byType(FlankerArrow), findsNWidgets(7));
  });
}
