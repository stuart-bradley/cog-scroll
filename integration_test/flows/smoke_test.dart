import 'package:cogscroll/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and renders the full Home on a real binding', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CogScrollApp()));
    await tester.pumpAndSettle();

    // On the real integration binding this exercises the bundled Space Grotesk
    // font and the edge-to-edge boot path — beyond the wordmark-only assertion
    // the widget test in test/app_test.dart already covers.
    expect(find.text('CogScroll'), findsOneWidget);
    expect(find.text('BRAIN TRAINING'), findsOneWidget);
  });
}
