import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSender implements FloconMessageSender {
  final sent = <({String plugin, String method, Map<String, dynamic> body})>[];
  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) => sent.add((
    plugin: plugin,
    method: method,
    body: jsonDecode(body) as Map<String, dynamic>,
  ));
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body, [this.contentType = 'application/json']);
  var calls = 0;
  final int status;
  final String body;
  final String contentType;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? s,
    Future<void>? c,
  ) async {
    calls++;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }
}

void main() {
  late FakeSender sender;
  late FloconNetworkPlugin plugin;
  Dio build(
    FakeAdapter adapter, [
    FloconNetworkOptions o = const FloconNetworkOptions(),
  ]) => Dio()
    ..httpClientAdapter = adapter
    ..interceptors.add(FloconDioInterceptor(plugin: plugin, networkOptions: o));

  setUp(() {
    sender = FakeSender();
    plugin = FloconNetworkPlugin(sender: sender);
  });

  test(
    'logs request then response with the same call id and explicit nulls',
    () async {
      final dio = build(FakeAdapter(200, '{"ok":true}'));
      await dio.post('https://x.test/a', data: {'a': 1});
      expect(sender.sent.map((m) => m.method), [
        'log_network_call_request',
        'log_network_call_response',
      ]);
      final req = sender.sent[0].body, res = sender.sent[1].body;
      expect(req['floconCallId'], res['floconCallId']);
      expect(req['floconNetworkType'], 'http');
      expect(req['method'], 'POST');
      expect(req['requestBody'], '{"a":1}');
      expect(res['responseHttpCode'], 200);
      expect(res['responseGrpcStatus'], null);
      expect(res.containsKey('responseError'), isTrue);
      expect(res['isImage'], false);
    },
  );

  test('http error status is logged with body, no responseError', () async {
    final dio = build(FakeAdapter(404, '{"e":1}'));
    await expectLater(
      dio.get('https://x.test/a'),
      throwsA(isA<DioException>()),
    );
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
    final dio = build(
      FakeAdapter(200, '{}'),
      FloconNetworkOptions(shouldLog: (_) => false),
    );
    await dio.get('https://x.test/a');
    expect(sender.sent, isEmpty);
  });

  test('websocket event payload', () {
    plugin.logWebSocketEvent(
      FloconWebSocketEvent(
        websocketUrl: 'wss://x',
        event: FloconWebSocketEventType.receiveMessage,
        message: 'héllo',
      ),
    );
    final b = sender.sent.single.body;
    expect(b['event'], 'received');
    expect(b['size'], 6);
    expect(b['error'], null);
  });

  group('mocks and bad network', () {
    late FakeAdapter adapter;
    late Dio dio;
    FloconMessageFromServer setup(String method, Object body) =>
        FloconMessageFromServer(
          plugin: 'network',
          method: method,
          body: jsonEncode(body),
        );

    setUp(() {
      adapter = FakeAdapter(200, '{"real":true}');
      dio = build(adapter);
    });

    test(
      'a mock answers without touching the network and is logged as mocked',
      () async {
        plugin.onMessageReceived(
          setup('setup_mocks', [
            {
              'expectation': {
                'urlPattern': r'https://x\.test/a',
                'method': 'GET',
              },
              'response': {
                'httpCode': 201,
                'body': '{"mock":1}',
                'mediaType': 'application/json',
                'delay': 0,
                'headers': {'x-mock': 'yes'},
              },
            },
          ]),
        );
        final response = await dio.get<dynamic>('https://x.test/a');
        expect(response.statusCode, 201);
        expect(response.data, {'mock': 1});
        expect(response.headers.value('x-mock'), 'yes');
        expect(adapter.calls, 0);
        expect(sender.sent.map((m) => m.method), [
          'log_network_call_request',
          'log_network_call_response',
        ]);
        expect(sender.sent[0].body['isMocked'], true);
        expect(sender.sent[1].body['isMocked'], true);
        expect(sender.sent[1].body['responseHttpCode'], 201);
        expect(sender.sent[1].body['responseBody'], '{"mock":1}');
      },
    );

    test('a non-matching url goes through to the network', () async {
      plugin.onMessageReceived(
        setup('setup_mocks', [
          {
            'expectation': {
              'urlPattern': 'https://other.test/.*',
              'method': '*',
            },
            'response': {'httpCode': 500, 'body': '', 'delay': 0},
          },
        ]),
      );
      final response = await dio.get<dynamic>('https://x.test/a');
      expect(response.data, {'real': true});
      expect(adapter.calls, 1);
      expect(sender.sent[0].body['isMocked'], false);
    });

    test(
      'an error status mock is rejected like a real error response',
      () async {
        plugin.onMessageReceived(
          setup('setup_mocks', [
            {
              'expectation': {'urlPattern': '.*', 'method': '*'},
              'response': {'httpCode': 404, 'body': 'nope', 'delay': 0},
            },
          ]),
        );
        await expectLater(
          dio.get<dynamic>('https://x.test/a'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              404,
            ),
          ),
        );
        expect(sender.sent[1].body['responseHttpCode'], 404);
        expect(sender.sent[1].body['responseError'], null);
      },
    );

    test('an exception mock is thrown as a Dio error and logged', () async {
      plugin.onMessageReceived(
        setup('setup_mocks', [
          {
            'expectation': {'urlPattern': '.*', 'method': '*'},
            'response': {
              'errorException': 'java.net.SocketTimeoutException',
              'delay': 0,
            },
          },
        ]),
      );
      await expectLater(
        dio.get<dynamic>('https://x.test/a'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionTimeout,
          ),
        ),
      );
      expect(
        sender.sent[1].body['responseError'],
        'java.net.SocketTimeoutException',
      );
      expect(sender.sent[1].body['isMocked'], true);
    });

    test(
      'a bad network error rate of 1 fails the call, not flagged as mocked',
      () async {
        plugin.onMessageReceived(
          setup('setup_bad_network_config', {
            'latency': {
              'latencyTriggerProbability': 0,
              'minLatencyMs': 0,
              'maxLatencyMs': 0,
            },
            'errorProbability': 1,
            'errors': [
              {
                'weight': 1,
                'errorCode': 503,
                'errorBody': 'down',
                'errorContentType': 'text/plain',
              },
            ],
          }),
        );
        await expectLater(
          dio.get<dynamic>('https://x.test/a'),
          throwsA(isA<DioException>()),
        );
        expect(adapter.calls, 0);
        expect(sender.sent[1].body['responseHttpCode'], 503);
        expect(sender.sent[1].body['isMocked'], false);
      },
    );
  });
}
