/// A key-value store shown in the Preferences section of the Flocon desktop app.
abstract interface class FloconPreference {
  /// Name of the store in the desktop app. Must be unique.
  String get name;

  Future<List<String>> keys();

  /// The value of a key, or null if it has no value the desktop can show.
  Future<FloconPreferenceValue?> value(String key);

  /// Writes a value edited in the desktop. Only written when its type matches the stored one.
  Future<void> setValue(String key, FloconPreferenceValue value);
}

/// A preference value in one of the types the desktop can show and edit. Exactly one is set.
class FloconPreferenceValue {
  const FloconPreferenceValue({
    this.stringValue,
    this.intValue,
    this.longValue,
    this.floatValue,
    this.booleanValue,
    this.setStringValue,
  });

  final String? stringValue;
  final int? intValue;
  final int? longValue;
  final double? floatValue;
  final bool? booleanValue;
  final List<String>? setStringValue;
}
