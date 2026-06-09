import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CorsiState state({
    CorsiFeedback? fb,
    CorsiStage stage = CorsiStage.recall,
    int gridN = 4,
    int bad = -1,
  }) => (
    phase: GamePhase.playing,
    stage: stage,
    gridN: gridN,
    level: 3,
    trial: 0,
    trials: 6,
    lit: -1,
    taps: const [],
    bad: bad,
    fb: fb,
    summary: null,
  );

  Widget host(CorsiState s) => MaterialApp(
    home: Scaffold(
      body: CorsiPlaying(state: s, onTapCell: (_) {}),
    ),
  );

  testWidgets('renders a 4×4 grid of cells', (tester) async {
    await tester.pumpWidget(host(state()));
    expect(find.byKey(const ValueKey('corsi-cell-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('corsi-cell-15')), findsOneWidget);
    expect(find.byKey(const ValueKey('corsi-cell-16')), findsNothing);
  });

  testWidgets('grows to a 5×5 grid when the span has grown', (tester) async {
    await tester.pumpWidget(host(state(gridN: 5)));
    expect(find.byKey(const ValueKey('corsi-cell-24')), findsOneWidget);
  });

  testWidgets('a correct sequence pulses over the grid (still visible)', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: CorsiFeedback.hit)));
    expect(find.byType(Pulse), findsOneWidget);
    expect(find.byKey(const ValueKey('corsi-cell-0')), findsOneWidget);
  });

  testWidgets('a wrong cell shakes the grid and marks the bad cell', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(fb: CorsiFeedback.wrong, bad: 2)));
    expect(find.byType(Shake), findsOneWidget);
    expect(find.byType(Cross), findsOneWidget); // the marked wrong cell
  });
}
