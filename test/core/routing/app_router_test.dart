import 'package:cogscroll/core/analytics/app_database.dart';
import 'package:cogscroll/core/analytics/app_database_provider.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/main.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {required bool prompted}) async {
    SharedPreferences.setMockInitialValues({});
    final store = CsStore(await SharedPreferences.getInstance());
    if (prompted) await store.setJson(CsStoreKeys.baselinePrompted, true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          csStoreProvider.overrideWithValue(store),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const CogScrollApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a first launch (no prompt flag) is redirected to baseline', (
    tester,
  ) async {
    await pumpApp(tester, prompted: false);
    expect(find.text('Find your baseline'), findsOneWidget);
  });

  testWidgets('once prompted, a launch lands on the catalog', (tester) async {
    await pumpApp(tester, prompted: true);
    expect(find.text('CogScroll'), findsOneWidget);
    expect(find.text('BRAIN TRAINING'), findsOneWidget);
  });

  testWidgets('navigating to /baseline when prompted is NOT bounced away', (
    tester,
  ) async {
    await pumpApp(tester, prompted: true);
    // The dev "Run baseline" link must still reach the flow (no redirect loop).
    await tester.tap(find.text('RUN BASELINE'));
    await tester.pumpAndSettle();
    expect(find.text('Find your baseline'), findsOneWidget);
  });
}
