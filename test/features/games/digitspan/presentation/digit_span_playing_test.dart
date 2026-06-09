import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DigitSpanState state({
    DigitSpanFeedback? fb,
    DigitSpanStage stage = DigitSpanStage.recall,
    DigitSpanMode mode = DigitSpanMode.forward,
    int? digit,
    List<int> input = const [],
  }) => (
    phase: GamePhase.playing,
    mode: mode,
    stage: stage,
    level: 4,
    trial: 0,
    trials: 6,
    digit: digit,
    input: input,
    fb: fb,
    summary: null,
  );

  Widget host(DigitSpanState s) => MaterialApp(
    home: Scaffold(
      body: DigitSpanPlaying(state: s, onPad: (_) {}),
    ),
  );

  testWidgets('shows a popping digit during the show stage', (tester) async {
    await tester.pumpWidget(host(state(stage: DigitSpanStage.show, digit: 7)));
    expect(find.byType(Pop), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('recall shows the keypad', (tester) async {
    await tester.pumpWidget(host(state()));
    expect(find.byKey(const ValueKey('digit-key-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('digit-key-0')), findsOneWidget);
  });

  testWidgets('a correct recall blooms over the slots', (tester) async {
    await tester.pumpWidget(host(state(fb: DigitSpanFeedback.hit)));
    expect(find.byType(Bloom), findsOneWidget);
  });

  testWidgets('a wrong recall shakes', (tester) async {
    await tester.pumpWidget(host(state(fb: DigitSpanFeedback.wrong)));
    expect(find.byType(Shake), findsOneWidget);
  });

  testWidgets('backward mode shows the reverse hint during recall', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(mode: DigitSpanMode.backward)));
    expect(find.text('IN REVERSE'), findsOneWidget); // Label upper-cases
  });

  testWidgets('forward mode shows no reverse hint', (tester) async {
    await tester.pumpWidget(host(state()));
    expect(find.text('IN REVERSE'), findsNothing);
  });
}
