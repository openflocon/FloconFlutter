import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flocon_http/flocon_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String method, Map<String, dynamic> body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((method: method, body: jsonDecode(body) as Map<String, dynamic>));
}

void main() {
  late _Sender sender;
  late FloconNetworkPlugin plugin;
  setUp(() {
    sender = _Sender();
    plugin = FloconNetworkPlugin(sender: sender);
  });

  test('logs request and response and returns the body intact', () async {
    final client = FloconHttpClient(
      MockClient((r) async => http.Response('{"ok":true}', 200, headers: {'content-type': 'application/json'})),
      plugin: plugin,
    );
    final response = await client.post(Uri.parse('https://x.test/a'), body: 'hi');
    expect(response.body, '{"ok":true}');
    expect(sender.sent.map((m) => m.method), ['logNetworkCallRequest', 'logNetworkCallResponse']);
    expect(sender.sent[0].body['requestBody'], 'hi');
    expect(sender.sent[0].body['floconCallId'], sender.sent[1].body['floconCallId']);
    expect(sender.sent[1].body['responseHttpCode'], 200);
    expect(sender.sent[1].body['responseBody'], '{"ok":true}');
  });

  test('exceptions are logged and rethrown', () async {
    final client = FloconHttpClient(MockClient((r) async => throw http.ClientException('boom')), plugin: plugin);
    await expectLater(client.get(Uri.parse('https://x.test/a')), throwsA(isA<http.ClientException>()));
    expect(sender.sent[1].body['responseError'], contains('boom'));
  });

  test('images skip the body, shouldLog false skips the call', () async {
    final client = FloconHttpClient(
      MockClient((r) async => http.Response('png', 200, headers: {'content-type': 'image/png'})),
      plugin: plugin,
      shouldLog: (r) => !r.url.path.contains('skip'),
    );
    await client.get(Uri.parse('https://x.test/i.png'));
    expect(sender.sent[1].body['isImage'], true);
    expect(sender.sent[1].body['responseBody'], null);
    sender.sent.clear();
    await client.get(Uri.parse('https://x.test/skip'));
    expect(sender.sent, isEmpty);
  });
}
