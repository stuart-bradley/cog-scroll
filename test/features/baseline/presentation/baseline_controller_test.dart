import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CsStore store;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = CsStore(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [csStoreProvider.overrideWithValue(store)],
    );
  });
  tearDown(() => container.dispose());

  BaselineState read() => container.read(baselineControllerProvider);
  BaselineController ctrl() =>
      container.read(baselineControllerProvider.notifier);

  test('build opens on welcome and sets baselinePrompted', () {
    expect(read(), (stage: BaselineStage.welcome, step: 0));
    expect(store.getBool(CsStoreKeys.baselinePrompted), isTrue);
    // onboarded is NOT set just by opening the flow.
    expect(store.getBool(CsStoreKeys.onboarded), isNull);
  });

  test('start moves to the first playing game', () {
    ctrl().start();
    expect(read(), (stage: BaselineStage.playing, step: 0));
  });

  test('advance walks every game then reveals, setting onboarded last', () {
    ctrl().start();
    // Steps 0 → 5: advancing stays in playing and never sets onboarded.
    for (var i = 1; i < baselineSet.length; i++) {
      ctrl().advance();
      expect(read(), (stage: BaselineStage.playing, step: i));
      expect(store.getBool(CsStoreKeys.onboarded), isNull);
    }
    // Advancing past the last game completes the flow.
    ctrl().advance();
    expect(read().stage, BaselineStage.done);
    expect(store.getBool(CsStoreKeys.onboarded), isTrue);
  });

  test('skipping every game (advance only) still completes and onboards', () {
    ctrl().start();
    for (var i = 0; i < baselineSet.length; i++) {
      ctrl().advance();
    }
    expect(read().stage, BaselineStage.done);
    expect(store.getBool(CsStoreKeys.onboarded), isTrue);
  });
}
