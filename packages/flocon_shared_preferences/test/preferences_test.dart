import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:flocon_shared_preferences/src/shared_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Object body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as Object));
}

FloconMessageFromServer _msg(String method, Map<String, Object?> body) =>
    FloconMessageFromServer(plugin: 'sharedPreferences', method: method, body: jsonEncode(body));

void main() {
  late _Sender sender;
  late FloconPreferencesPlugin plugin;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'name': 'Florent',
      'dark': true,
      'count': 3,
      'big': 5000000000,
      'ratio': 1.5,
      'tags': ['a', 'b'],
    });
    prefs = await SharedPreferences.getInstance();
    sender = _Sender();
    plugin = FloconPreferencesPlugin(sender: sender)..registerAndNotify(SharedPreferencesStore(prefs, 'prefs'));
    sender.sent.clear();
  });

  test('sends the list of stores on connection', () {
    plugin.onConnectedToServer();
    expect(sender.sent.single.method, 'getSharedPreferences');
    expect(sender.sent.single.body, [
      {'name': 'prefs'}
    ]);
  });

  test('answers a content request with typed rows', () async {
    await plugin.handleMessage(_msg('getSharedPreferenceValue', {'requestId': 'r1', 'sharedPreferenceName': 'prefs'}));
    final body = sender.sent.single.body as Map<String, dynamic>;
    expect(body['requestId'], 'r1');
    final rows = {for (final r in body['rows'] as List) r['key'] as String: r as Map<String, dynamic>};
    expect(rows['name']!['stringValue'], 'Florent');
    expect(rows['dark']!['booleanValue'], true);
    expect(rows['count']!['intValue'], 3);
    expect(rows['big']!['longValue'], 5000000000);
    expect(rows['ratio']!['floatValue'], 1.5);
    expect(rows['tags']!['setStringValue'], ['a', 'b']);
    expect(rows['name']!.containsKey('intValue'), false);
  });

  test('applies an edit of the same type and answers with the new content', () async {
    await plugin.handleMessage(_msg('setSharedPreferenceValue',
        {'requestId': 'r2', 'sharedPreferenceName': 'prefs', 'key': 'count', 'intValue': 42}));
    expect(prefs.getInt('count'), 42);
    expect(sender.sent.single.method, 'getSharedPreferenceValue');
  });

  test('ignores an edit whose type does not match', () async {
    await plugin.handleMessage(_msg('setSharedPreferenceValue',
        {'requestId': 'r3', 'sharedPreferenceName': 'prefs', 'key': 'name', 'booleanValue': true}));
    expect(prefs.getString('name'), 'Florent');
  });

  test('registration is a no-op before Flocon.initialize', () {
    floconRegisterSharedPreferences(prefs);
  });
}
