import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and renders the dev catalog on a real binding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = CsStore(await SharedPreferences.getInstance());
    // Skip the first-run baseline redirect so the boot lands on the catalog.
    await store.setJson(CsStoreKeys.baselinePrompted, true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [csStoreProvider.overrideWithValue(store)],
        child: const CogScrollApp(),
      ),
    );
    await tester.pumpAndSettle();

    // On the real integration binding this exercises the bundled Space Grotesk
    // font and the edge-to-edge boot path beyond the widget test in
    // test/app_test.dart.
    expect(find.text('CogScroll'), findsOneWidget);
    expect(find.text('BRAIN TRAINING'), findsOneWidget);
  });
}
