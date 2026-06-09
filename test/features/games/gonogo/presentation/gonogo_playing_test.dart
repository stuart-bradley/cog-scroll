import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/ui_kit/countdown.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_state.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GngState state({
    GngFeedback? fb,
    int shape = gngGoShape,
    bool showing = true,
  }) => (
    phase: GamePhase.playing,
    level: 1,
    round: 24,
    idx: 0,
    shape: shape,
    showing: showing,
    fb: fb,
    summary: null,
    levelMsg: null,
  );

  Widget host(GngState s) => MaterialApp(
    home: Scaffold(
      body: GoNoGoPlaying(state: s, onTap: () {}),
    ),
  );

  testWidgets('an appearing stimulus pops in under a countdown', (
    tester,
  ) async {
    await tester.pumpWidget(host(state()));
    expect(find.byType(Countdown), findsOneWidget);
    expect(find.byType(Pop), findsOneWidget);
    expect(find.byType(Shape), findsOneWidget);
  });

  testWidgets('a correct Go-tap blooms around the circle (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: GngFeedback.correctGo)));
    expect(find.byType(Bloom), findsOneWidget);
    expect(find.byType(Shape), findsWidgets);
  });

  testWidgets('a correct withhold pulses around the No-Go (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(state(fb: GngFeedback.correctWithhold, shape: gngNoGoSquare)),
    );
    expect(find.byType(Pulse), findsOneWidget);
    expect(find.byType(Shape), findsWidgets);
  });

  testWidgets('a wrong answer shakes the stimulus (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: GngFeedback.wrong)));
    expect(find.byType(Shake), findsOneWidget);
    expect(find.byType(Shape), findsWidgets);
  });
}
