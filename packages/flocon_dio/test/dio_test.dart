import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSender implements FloconMessageSender {
  final sent = <({String plugin, String method, Map<String, dynamic> body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as Map<String, dynamic>));
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body, [this.contentType = 'application/json']);
  final int status;
  final String body;
  final String contentType;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: [contentType],
      });
}

void main() {
  late FakeSender sender;
  late FloconNetworkPlugin plugin;
  Dio build(FakeAdapter adapter, [FloconNetworkOptions o = const FloconNetworkOptions()]) =>
      Dio()
        ..httpClientAdapter = adapter
        ..interceptors.add(FloconDioInterceptor(plugin: plugin, networkOptions: o));

  setUp(() {
    sender = FakeSender();
    plugin = FloconNetworkPlugin(sender: sender);
  });

  test('logs request then response with the same call id and explicit nulls', () async {
    final dio = build(FakeAdapter(200, '{"ok":true}'));
    await dio.post('https://x.test/a', data: {'a': 1});
    expect(sender.sent.map((m) => m.method), ['logNetworkCallRequest', 'logNetworkCallResponse']);
    final req = sender.sent[0].body, res = sender.sent[1].body;
    expect(req['floconCallId'], res['floconCallId']);
    expect(req['floconNetworkType'], 'http');
    expect(req['method'], 'POST');
    expect(req['requestBody'], '{"a":1}');
    expect(res['responseHttpCode'], 200);
    expect(res['responseGrpcStatus'], null);
    expect(res.containsKey('responseError'), isTrue);
    expect(res['isImage'], false);
  });

  test('http error status is logged with body, no responseError', () async {
    final dio = build(FakeAdapter(404, '{"e":1}'));
    await expectLater(dio.get('https://x.test/a'), throwsA(isA<DioException>()));
    final res = sender.sent[1].body;
    expect(res['responseHttpCode'], 404);
    expect(res['responseBody'], '{"e":1}');
    expect(res['responseError'], null);
  });

  test('images do not send their body', () async {
    final dio = build(FakeAdapter(200, 'bytes', 'image/png'));
    await dio.get('https://x.test/i.png');
    final res = sender.sent[1].body;
    expect(res['isImage'], true);
    expect(res['responseBody'], null);
  });

  test('shouldLog false skips the call', () async {
    final dio = build(FakeAdapter(200, '{}'), FloconNetworkOptions(shouldLog: (_) => false));
    await dio.get('https://x.test/a');
    expect(sender.sent, isEmpty);
  });

  test('websocket event payload', () {
    plugin.logWebSocketEvent(FloconWebSocketEvent(
        websocketUrl: 'wss://x', event: FloconWebSocketEventType.receiveMessage, message: 'héllo'));
    final b = sender.sent.single.body;
    expect(b['event'], 'received');
    expect(b['size'], 6);
    expect(b['error'], null);
  });
}
