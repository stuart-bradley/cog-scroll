import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/features/games/nback/domain/nback_state.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NbackState state(NbackFeedback? fb) => (
    phase: GamePhase.playing,
    n: 1,
    idx: 0,
    shape: 0,
    showing: true,
    fb: fb,
    summary: null,
    levelMsg: null,
  );

  Widget host(NbackFeedback? fb) => MaterialApp(
    home: Scaffold(
      body: NbackPlaying(state: state(fb), round: 20, onTap: () {}),
    ),
  );

  testWidgets('an appearing stimulus pops in', (tester) async {
    await tester.pumpWidget(host(null));
    expect(find.byType(Pop), findsOneWidget);
    expect(find.byType(Shape), findsOneWidget);
  });

  testWidgets('a hit blooms a ring around the stimulus', (tester) async {
    await tester.pumpWidget(host(NbackFeedback.hit));
    expect(find.byType(Bloom), findsOneWidget);
    expect(find.byType(Shape), findsWidgets); // stimulus stays visible
  });

  testWidgets('a wrong answer shakes with two ghost outlines', (tester) async {
    await tester.pumpWidget(host(NbackFeedback.wrong));
    expect(find.byType(Shake), findsOneWidget);
    // The main outline + two ghost copies (csGhostA/B).
    expect(find.byType(Shape), findsNWidgets(3));
  });
}
