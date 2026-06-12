import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/runner_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RunnerContext ctx({
    int index = 0,
    int total = 3,
    String? headerLabel = 'Baseline',
    void Function()? onExit,
    void Function()? onSkip,
  }) => RunnerContext(
    index: index,
    total: total,
    domain: 'X',
    focus: false,
    headerLabel: headerLabel,
    onExit: onExit,
    onDone: (_) {},
    onSkip: onSkip ?? () {},
  );

  Widget host(RunnerContext runner) =>
      MaterialApp(home: Scaffold(body: RunnerHeader(runner)));

  testWidgets('renders the "<label> · NN / TT" step count', (tester) async {
    await tester.pumpWidget(host(ctx()));
    expect(find.text('BASELINE · 01 / 03'), findsOneWidget);
  });

  testWidgets('shows just the count when headerLabel is null', (tester) async {
    await tester.pumpWidget(host(ctx(headerLabel: null, index: 1, total: 6)));
    expect(find.text('02 / 06'), findsOneWidget);
  });

  testWidgets('Skip taps fire onSkip', (tester) async {
    var skipped = false;
    await tester.pumpWidget(host(ctx(onSkip: () => skipped = true)));
    await tester.tap(find.text('SKIP'));
    expect(skipped, isTrue);
  });

  testWidgets('the exit ✕ fires onExit when provided', (tester) async {
    var exited = false;
    await tester.pumpWidget(host(ctx(onExit: () => exited = true)));
    expect(find.byType(Cross), findsOneWidget);
    await tester.tap(find.byType(Cross));
    expect(exited, isTrue);
  });

  testWidgets('the exit ✕ is hidden when onExit is null', (tester) async {
    await tester.pumpWidget(host(ctx()));
    expect(find.byType(Cross), findsNothing);
  });

  testWidgets('renders one progress segment per step', (tester) async {
    await tester.pumpWidget(host(ctx(total: 6)));
    final progress = tester.widget<Row>(
      find.byKey(const Key('runner_progress')),
    );
    // Six bars interleaved with five 6px gaps.
    expect(progress.children.whereType<Expanded>().length, 6);
  });

  testWidgets('progress bars colour done/current/upcoming by step', (
    tester,
  ) async {
    await tester.pumpWidget(host(ctx(index: 2, total: 6)));
    final bars = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('runner_progress')),
            matching: find.byType(Container),
          ),
        )
        .toList();
    expect(bars.length, 6);
    Color colourOf(int i) => (bars[i].decoration! as BoxDecoration).color!;
    // Done (i < index) = fg, current (i == index) = sub, upcoming = line.
    expect(colourOf(0), CsTokens.fg);
    expect(colourOf(1), CsTokens.fg);
    expect(colourOf(2), CsTokens.sub);
    expect(colourOf(3), CsTokens.line);
    expect(colourOf(5), CsTokens.line);
  });
}
