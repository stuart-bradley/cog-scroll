import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/app_database_provider.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_runner_screen.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_playing.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_header.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../games/shared/fakes.dart';

void main() {
  late CsStore store;
  late AppDatabase db;
  late FakeGameSink sink;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = CsStore(await SharedPreferences.getInstance());
    db = AppDatabase(NativeDatabase.memory());
    sink = FakeGameSink();
  });
  tearDown(() => db.close());

  // With [fakeSink], games record into the capturable fake; without it they use
  // the real analytics sink (the in-memory Drift DB).
  Widget app({FakeGameSink? fakeSink}) {
    final router = GoRouter(
      initialLocation: '/baseline',
      routes: [
        GoRoute(
          path: '/baseline',
          builder: (_, _) => const BaselineRunnerScreen(),
        ),
        GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
      ],
    );
    return ProviderScope(
      overrides: [
        csStoreProvider.overrideWithValue(store),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
        if (fakeSink != null) gameSinkProvider.overrideWithValue(fakeSink),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Skips through every game from the welcome screen to the reveal.
  Future<void> skipAll(WidgetTester tester) async {
    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();
    for (var i = 0; i < baselineSet.length; i++) {
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
    }
  }

  /// Pumps in small steps until [finder] matches (games schedule random-delay
  /// timers, so we can't pumpAndSettle through play).
  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 120; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('timed out waiting for $finder');
  }

  testWidgets('welcome → Begin mounts the first game under the header', (
    tester,
  ) async {
    await tester.pumpWidget(app(fakeSink: sink));
    await tester.pumpAndSettle();
    expect(find.text('Find your baseline'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(RunnerHeader), findsOneWidget);
    expect(find.text('BASELINE · 01 / 06'), findsOneWidget);
  });

  testWidgets('skipping every game completes, records nothing, reveals 0/6', (
    tester,
  ) async {
    await tester.pumpWidget(app(fakeSink: sink));
    await tester.pumpAndSettle();
    await skipAll(tester);

    expect(find.text('Your starting map'), findsOneWidget);
    expect(store.getBool(CsStoreKeys.onboarded), isTrue);
    expect(store.getBool(CsStoreKeys.baselinePrompted), isTrue);
    // Skip never finishes a game, so nothing is recorded (domains stay null).
    expect(sink.calls, isEmpty);
    expect(find.textContaining('0 of 6 domains seeded'), findsOneWidget);

    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('the reveal reads seeded scores (all six measured)', (
    tester,
  ) async {
    for (final domain in Domains.all) {
      await db.analyticsDao.recordResult(domain, 60, DateTime.utc(2026));
    }
    await tester.pumpWidget(app(fakeSink: sink));
    await tester.pumpAndSettle();
    await skipAll(tester);

    expect(find.textContaining('All six domains seeded'), findsOneWidget);
  });

  testWidgets('playing the first game seeds its domain and advances', (
    tester,
  ) async {
    // Real analytics sink (no fakeSink) so the played game seeds the DB.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('BEGIN')); // welcome → reaction intro
    await tester.pumpAndSettle();
    await tester.tap(find.text('BEGIN')); // reaction intro → playing
    await tester.pump();

    final trials = baselineSet.first.trials ?? 0;
    for (var t = 0; t < trials; t++) {
      await pumpUntil(tester, find.byType(Pop)); // stimulus shown
      await tester.tap(find.byType(ReactionPlaying));
      await tester.pump(); // → result
      await tester.pump(const Duration(seconds: 1)); // inter-trial gap
    }
    await tester.pumpAndSettle();

    // Finishing Reaction advances to game two…
    expect(find.text('BASELINE · 02 / 06'), findsOneWidget);
    // …and seeds its domain in analytics.
    final scores = await db.analyticsDao.readScores();
    expect(scores.keys, contains('Processing Speed'));
  });

  testWidgets('a really-played score reaches the final reveal (not seeded)', (
    tester,
  ) async {
    // Real analytics sink — the reveal must read a score produced by play, not
    // pre-seeded, guarding decision-4's recordResult → onDone → reveal ordering
    // through the whole flow.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('BEGIN')); // welcome → reaction intro
    await tester.pumpAndSettle();
    await tester.tap(find.text('BEGIN')); // reaction intro → playing
    await tester.pump();

    final trials = baselineSet.first.trials ?? 0;
    for (var t = 0; t < trials; t++) {
      await pumpUntil(tester, find.byType(Pop));
      await tester.tap(find.byType(ReactionPlaying));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // Skip the remaining five games to reach the reveal.
    for (var i = 1; i < baselineSet.length; i++) {
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
    }

    // The reveal reports exactly the one really-played domain.
    expect(find.text('Your starting map'), findsOneWidget);
    expect(find.textContaining('1 of 6 domains seeded'), findsOneWidget);
  });

  testWidgets('"Maybe later" exits to Home without onboarding', (tester) async {
    await tester.pumpWidget(app(fakeSink: sink));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MAYBE LATER'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(store.getBool(CsStoreKeys.onboarded), isNull);
    // The prompt flag is still set on open, so the user won't be re-nagged.
    expect(store.getBool(CsStoreKeys.baselinePrompted), isTrue);
  });
}
