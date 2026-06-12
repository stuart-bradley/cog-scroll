import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_playing.dart';
import 'package:cogscroll/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pumps in small steps until [finder] matches (games schedule random-delay
  // timers, so we can't pumpAndSettle through play).
  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 120; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('timed out waiting for $finder');
  }

  // The full first-run flow on a real binding (real Drift DB): a fresh launch
  // is redirected into the baseline, plays the first game (seeding its domain),
  // skips the rest to the seeded radar, returns Home, and is not re-prompted on
  // relaunch.
  testWidgets('first run: redirect → play one, skip rest → reveal → home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = CsStore(await SharedPreferences.getInstance());
    Widget app() => ProviderScope(
      overrides: [csStoreProvider.overrideWithValue(store)],
      child: const CogScrollApp(),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // A first launch is redirected into the baseline and the prompt is marked.
    expect(find.text('Find your baseline'), findsOneWidget);
    expect(store.getBool(CsStoreKeys.baselinePrompted), isTrue);

    // Welcome → the first game (Reaction) under the unified header.
    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();
    expect(find.text('BASELINE · 01 / 06'), findsOneWidget);

    // Play Reaction's abbreviated trials to seed Processing Speed.
    await tester.tap(find.text('BEGIN')); // the game's own intro
    await tester.pump();
    final reactionTrials = baselineSet.first.trials ?? 0;
    for (var trial = 0; trial < reactionTrials; trial++) {
      await pumpUntil(tester, find.byType(Pop)); // wait for the stimulus
      await tester.tap(find.byType(ReactionPlaying));
      await tester.pump(); // → result
      await tester.pump(const Duration(seconds: 1)); // inter-trial gap
    }
    await tester.pumpAndSettle();

    // Now on game two — skip the remaining five.
    for (var i = 1; i < baselineSet.length; i++) {
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
    }

    // Reveal: onboarded, with exactly the one played domain seeded.
    expect(find.text('Your starting map'), findsOneWidget);
    expect(store.getBool(CsStoreKeys.onboarded), isTrue);
    expect(find.textContaining('1 of 6 domains seeded'), findsOneWidget);

    // Done → Home.
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('CogScroll'), findsOneWidget);

    // Relaunch: already prompted + onboarded, so no baseline redirect.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Find your baseline'), findsNothing);
    expect(find.text('CogScroll'), findsOneWidget);
  });
}
