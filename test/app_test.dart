import 'package:cogscroll/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CogScrollApp boots to the placeholder home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CogScrollApp()));
    await tester.pumpAndSettle();

    expect(find.text('CogScroll'), findsOneWidget);
  });
}
