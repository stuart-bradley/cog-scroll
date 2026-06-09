import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A typed facade over [SharedPreferences] mirroring the prototype's `CS.store`
/// (`docs/design/cs-data.jsx`): every key is namespaced with a `cogscroll:`
/// prefix and every value is JSON-encoded, so stored data stays
/// wire-compatible with the prototype's export files.
class CsStore {
  /// Wraps an already-initialised [SharedPreferences] instance.
  CsStore(this._prefs);

  /// The namespace every CogScroll key is stored under.
  static const prefix = 'cogscroll:';

  final SharedPreferences _prefs;

  String _k(String key) => '$prefix$key';

  /// Reads [key] and JSON-decodes it as [T], or returns null when the key is
  /// absent or decodes to a different type.
  T? getJson<T>(String key) {
    final raw = _prefs.getString(_k(key));
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is T ? decoded : null;
  }

  /// JSON-encodes [value] under [key]. A null [value] removes the key.
  Future<void> setJson(String key, Object? value) {
    if (value == null) return remove(key);
    return _prefs.setString(_k(key), jsonEncode(value));
  }

  /// Reads [key] as an int (JSON numbers decode to [num]), or null.
  int? getInt(String key) => getJson<num>(key)?.toInt();

  /// Reads [key] as a double, or null.
  double? getDouble(String key) => getJson<num>(key)?.toDouble();

  /// Reads [key] as a bool, or null.
  bool? getBool(String key) => getJson<bool>(key);

  /// Reads [key] as a String, or null.
  String? getString(String key) => getJson<String>(key);

  /// Removes [key].
  Future<void> remove(String key) => _prefs.remove(_k(key));

  /// Every stored CogScroll key, with the [prefix] stripped.
  Set<String> keys() => _prefs
      .getKeys()
      .where((k) => k.startsWith(prefix))
      .map((k) => k.substring(prefix.length))
      .toSet();
}
