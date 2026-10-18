import 'package:shared_preferences/shared_preferences.dart';

import 'preference.dart';

/// Exposes a [SharedPreferences] instance to the desktop.
class SharedPreferencesStore implements FloconPreference {
  SharedPreferencesStore(this._prefs, this.name);

  final SharedPreferences _prefs;

  @override
  final String name;

  // Pick up the changes made natively or by another isolate.
  Future<void> _refresh() async {
    try {
      await _prefs.reload();
    } catch (_) {}
  }

  @override
  Future<List<String>> keys() async {
    await _refresh();
    return _prefs.getKeys().toList()..sort();
  }

  @override
  Future<FloconPreferenceValue?> value(String key) async {
    final value = _prefs.get(key);
    return switch (value) {
      String() => FloconPreferenceValue(stringValue: value),
      bool() => FloconPreferenceValue(booleanValue: value),
      int() => value >= -0x80000000 && value <= 0x7fffffff
          ? FloconPreferenceValue(intValue: value)
          : FloconPreferenceValue(longValue: value),
      double() => FloconPreferenceValue(floatValue: value),
      List<String>() => FloconPreferenceValue(setStringValue: value),
      _ => null,
    };
  }

  @override
  Future<void> setValue(String key, FloconPreferenceValue value) async {
    final current = _prefs.get(key);
    switch (current) {
      case String() when value.stringValue != null:
        await _prefs.setString(key, value.stringValue!);
      case bool() when value.booleanValue != null:
        await _prefs.setBool(key, value.booleanValue!);
      case int() when (value.longValue ?? value.intValue) != null:
        await _prefs.setInt(key, (value.longValue ?? value.intValue)!);
      case double() when (value.floatValue ?? value.intValue) != null:
        await _prefs.setDouble(key, (value.floatValue ?? value.intValue)!.toDouble());
      case List<String>() when value.setStringValue != null:
        await _prefs.setStringList(key, value.setStringValue!);
      default:
        // missing key or type mismatch: ignored
        break;
    }
  }
}
