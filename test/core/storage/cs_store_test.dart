import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CsStore> store() async =>
      CsStore(await SharedPreferences.getInstance());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips JSON values', () async {
    final s = await store();
    await s.setJson(CsStoreKeys.nbackN, 3);
    expect(s.getInt(CsStoreKeys.nbackN), 3);
  });

  test('applies the cogscroll: prefix to the raw key', () async {
    SharedPreferences.setMockInitialValues({'cogscroll:nback-n': '3'});
    final s = await store();
    expect(s.getInt('nback-n'), 3);
  });

  test('keys() returns prefix-stripped CogScroll keys only', () async {
    SharedPreferences.setMockInitialValues({
      'cogscroll:onboarded': 'true',
      'cogscroll:nback-n': '2',
      'unrelated': 'x',
    });
    final s = await store();
    expect(s.keys(), {'onboarded', 'nback-n'});
  });

  test('typed getters decode each value, and missing keys are null', () async {
    final s = await store();
    await s.setJson('a-bool', true);
    await s.setJson('a-str', 'hi');
    await s.setJson('a-double', 2.5);
    expect(s.getBool('a-bool'), true);
    expect(s.getString('a-str'), 'hi');
    expect(s.getDouble('a-double'), 2.5);
    expect(s.getInt('missing'), isNull);
    expect(s.getBool('a-str'), isNull); // wrong type → null
  });

  test('setJson(null) and remove() delete the key', () async {
    final s = await store();
    await s.setJson('x', 1);
    await s.setJson('x', null);
    expect(s.getInt('x'), isNull);

    await s.setJson('y', 1);
    await s.remove('y');
    expect(s.getInt('y'), isNull);
  });
}
