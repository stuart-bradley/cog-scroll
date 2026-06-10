import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/trails/domain/trails_engine.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_playing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const targets = <TrailTarget>[
    (x: 60, y: 80, label: '1'),
    (x: 200, y: 160, label: 'A'),
    (x: 120, y: 320, label: '2'),
    (x: 260, y: 460, label: 'B'),
  ];

  TrailsState state({int next = 0, int? bad, int level = 1}) => (
    phase: GamePhase.playing,
    mode: TrailMode.b,
    level: level,
    count: targets.length,
    targets: targets,
    next: next,
    bad: bad,
    elapsed: 0,
    summary: null,
    levelMsg: null,
  );

  Widget host(TrailsState s, {void Function(int index)? onTap}) => MaterialApp(
    home: Scaffold(
      body: TrailsPlaying(state: s, onTapDot: onTap ?? (_) {}),
    ),
  );

  testWidgets('renders a keyed, labelled dot per target', (tester) async {
    await tester.pumpWidget(host(state()));
    for (var i = 0; i < targets.length; i++) {
      expect(find.byKey(ValueKey('trail-dot-$i')), findsOneWidget);
    }
    expect(find.text('1'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('tapping a dot reports its sequence index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(host(state(), onTap: taps.add));
    await tester.tap(find.byKey(const ValueKey('trail-dot-2')));
    expect(taps, [2]);
  });

  testWidgets('the polyline connects exactly the done dots', (tester) async {
    await tester.pumpWidget(host(state(next: 3)));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<TrailPathPainter>()
        .single;
    expect(painter.points, const [
      Offset(60, 80),
      Offset(200, 160),
      Offset(120, 320),
    ]);
  });

  testWidgets('a wrong tap shakes that dot, label still visible', (
    tester,
  ) async {
    await tester.pumpWidget(host(state(bad: 1)));
    final shake = find.byType(Shake);
    expect(shake, findsOneWidget);
    // The shaken stimulus stays visible — its label is inside the Shake.
    expect(
      find.descendant(of: shake, matching: find.text('A')),
      findsOneWidget,
    );
    // The motion is sped up to complete within the 360ms flash window.
    expect(
      tester.widget<Shake>(shake).duration,
      lessThanOrEqualTo(trailsBadFlash),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('no shake renders when nothing is flagged bad', (tester) async {
    await tester.pumpWidget(host(state()));
    expect(find.byType(Shake), findsNothing);
  });

  testWidgets('small-dot levels keep the ≥44px hit area', (tester) async {
    await tester.pumpWidget(host(state(level: 5)));
    final hit = tester.getSize(find.byKey(const ValueKey('trail-dot-0')));
    expect(hit.width, greaterThanOrEqualTo(44));
    expect(hit.height, greaterThanOrEqualTo(44));
  });
}
