import 'package:cogscroll/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the home wordmark', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CogScrollApp()));
    await tester.pumpAndSettle();

    expect(find.text('CogScroll'), findsOneWidget);
  });
}
