import 'dart:async';
import 'dart:convert';

import 'package:flocon/flocon.dart';

import 'preference.dart';

/// Shows the preference stores of the app in the Flocon desktop app, and applies the edits
/// made there. The list of stores is sent on each connection; the desktop then asks for the
/// content of the displayed store and sends the edited values.
class FloconPreferencesPlugin implements FloconPlugin {
  FloconPreferencesPlugin({required FloconMessageSender sender}) : _sender = sender;

  static const name = 'sharedPreferences';
  // app -> desktop, and desktop -> app for the two requests
  static const methodGetSharedPreferences = 'getSharedPreferences';
  static const methodGetSharedPreferenceValue = 'getSharedPreferenceValue';
  // desktop -> app
  static const methodSetSharedPreferenceValue = 'setSharedPreferenceValue';

  final FloconMessageSender _sender;
  final Map<String, FloconPreference> _preferences = {};

  @override
  String get pluginName => name;

  /// Adds a store (or replaces the one with the same name) and sends the updated list.
  void registerAndNotify(FloconPreference preference) {
    _preferences[preference.name] = preference;
    sendPreferenceList();
  }

  @override
  void onConnectedToServer() => sendPreferenceList();

  @override
  void onMessageReceived(FloconMessageFromServer message) => unawaited(handleMessage(message));

  Future<void> handleMessage(FloconMessageFromServer message) async {
    try {
      switch (message.method) {
        case methodGetSharedPreferences:
          sendPreferenceList();
        case methodGetSharedPreferenceValue:
          final request = jsonDecode(message.body) as Map<String, dynamic>;
          final preference = _preferences[request['sharedPreferenceName']];
          if (preference != null) await _sendContent(preference, request['requestId'] as String);
        case methodSetSharedPreferenceValue:
          final request = jsonDecode(message.body) as Map<String, dynamic>;
          final preference = _preferences[request['sharedPreferenceName']];
          if (preference == null) return;
          await preference.setValue(
            request['key'] as String,
            FloconPreferenceValue(
              stringValue: request['stringValue'] as String?,
              intValue: (request['intValue'] as num?)?.toInt(),
              longValue: (request['longValue'] as num?)?.toInt(),
              floatValue: (request['floatValue'] as num?)?.toDouble(),
              booleanValue: request['booleanValue'] as bool?,
              setStringValue: (request['setStringValue'] as List?)?.cast<String>(),
            ),
          );
          // send the content again, so that the desktop shows what was actually stored
          await _sendContent(preference, request['requestId'] as String);
      }
    } catch (_) {
      // an unreadable request must never break the app
    }
  }

  void sendPreferenceList() {
    final names = _preferences.keys.toList()..sort();
    _send(methodGetSharedPreferences, [for (final n in names) {'name': n}]);
  }

  Future<void> _sendContent(FloconPreference preference, String requestId) async {
    final rows = <Map<String, Object?>>[];
    for (final key in await preference.keys()) {
      final v = await preference.value(key);
      // only the property matching the type of the value is sent
      rows.add({
        'key': key,
        if (v?.stringValue != null) 'stringValue': v!.stringValue,
        if (v?.intValue != null) 'intValue': v!.intValue,
        if (v?.floatValue != null) 'floatValue': v!.floatValue,
        if (v?.booleanValue != null) 'booleanValue': v!.booleanValue,
        if (v?.longValue != null) 'longValue': v!.longValue,
        if (v?.setStringValue != null) 'setStringValue': v!.setStringValue,
      });
    }
    _send(methodGetSharedPreferenceValue, {
      'requestId': requestId,
      'sharedPreferenceName': preference.name,
      'rows': rows,
    });
  }

  void _send(String method, Object value) {
    try {
      _sender.send(plugin: pluginName, method: method, body: jsonEncode(value));
    } catch (_) {}
  }
}
