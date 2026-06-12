import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/app_database_provider.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/radar.dart';
import 'package:cogscroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// Seeds the in-memory DB: one improving domain (5 results), one under-3
  /// domain (1 result), and the rest left unmeasured.
  Future<void> seed() async {
    final dao = db.analyticsDao;
    final t = DateTime.utc(2026, 6);
    for (var i = 0; i < 5; i++) {
      await dao.recordResult(
        Domains.workingMemory,
        50 + i * 6, // 50,56,62,68,74 → EMA 66, trend improving
        t.add(Duration(days: i)),
      );
    }
    await dao.recordResult(Domains.processingSpeed, 40, t); // 1 result → none
  }

  Widget host() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );

  testWidgets('renders the radar and a row per domain', (tester) async {
    await seed();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(Radar), findsOneWidget);
    for (final domain in Domains.all) {
      expect(find.text(domain), findsOneWidget, reason: 'row for $domain');
    }
  });

  testWidgets('shows the under-3 fallback and unmeasured dashes', (
    tester,
  ) async {
    await seed();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // processingSpeed (1 result) + the four untouched domains show it.
    expect(find.text('Not enough data yet'), findsWidgets);
    // The four untouched domains render an em dash for their score.
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('shows the measured score and improving trend', (tester) async {
    await seed();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('66'), findsOneWidget); // workingMemory EMA
    expect(find.text('IMPROVING'), findsOneWidget);
  });

  testWidgets('footer counts measured domains', (tester) async {
    await seed();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('2 OF 6 DOMAINS MEASURED'),
      findsOneWidget,
    );
  });
}
