import 'dart:async';
import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flocon_http/flocon_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String method, Map<String, dynamic> body})>[];
  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) => sent.add((
    method: method,
    body: jsonDecode(body) as Map<String, dynamic>,
  ));
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
      MockClient(
        (r) async => http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      plugin: plugin,
    );
    final response = await client.post(
      Uri.parse('https://x.test/a'),
      body: 'hi',
    );
    expect(response.body, '{"ok":true}');
    expect(sender.sent.map((m) => m.method), [
      'log_network_call_request',
      'log_network_call_response',
    ]);
    expect(sender.sent[0].body['requestBody'], 'hi');
    expect(
      sender.sent[0].body['floconCallId'],
      sender.sent[1].body['floconCallId'],
    );
    expect(sender.sent[1].body['responseHttpCode'], 200);
    expect(sender.sent[1].body['responseBody'], '{"ok":true}');
  });

  test('exceptions are logged and rethrown', () async {
    final client = FloconHttpClient(
      MockClient((r) async => throw http.ClientException('boom')),
      plugin: plugin,
    );
    await expectLater(
      client.get(Uri.parse('https://x.test/a')),
      throwsA(isA<http.ClientException>()),
    );
    expect(sender.sent[1].body['responseError'], contains('boom'));
  });

  test('images skip the body, shouldLog false skips the call', () async {
    final client = FloconHttpClient(
      MockClient(
        (r) async =>
            http.Response('png', 200, headers: {'content-type': 'image/png'}),
      ),
      plugin: plugin,
    );
    plugin.options = FloconNetwork(shouldLog: (r) => !r.url.path.contains('skip'));
    await client.get(Uri.parse('https://x.test/i.png'));
    expect(sender.sent[1].body['isImage'], true);
    expect(sender.sent[1].body['responseBody'], null);
    sender.sent.clear();
    await client.get(Uri.parse('https://x.test/skip'));
    expect(sender.sent, isEmpty);
  });

  test('isImage of FloconNetwork marks a response without image content type', () async {
    plugin.options = FloconNetwork(isImage: (request, response) => request.url.host == 'img.test');
    final client = FloconHttpClient(MockClient((r) async => http.Response('bytes', 200)), plugin: plugin);
    await client.get(Uri.parse('https://img.test/1'));
    expect(sender.sent[1].body['isImage'], true);
    expect(sender.sent[1].body['responseBody'], null);
  });

  test('withFlocon wraps the client', () {
    expect(http.Client().withFlocon(), isA<FloconHttpClient>());
  });

  group('mocks and bad network', () {
    var networkCalls = 0;
    late FloconHttpClient client;

    FloconMessageFromServer setup(String method, Object body) =>
        FloconMessageFromServer(
          plugin: 'network',
          method: method,
          body: jsonEncode(body),
        );

    setUp(() {
      networkCalls = 0;
      client = FloconHttpClient(
        MockClient((r) async {
          networkCalls++;
          return http.Response('real', 200);
        }),
        plugin: plugin,
      );
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
        final response = await client.get(Uri.parse('https://x.test/a'));
        expect(response.statusCode, 201);
        expect(response.body, '{"mock":1}');
        expect(response.headers['x-mock'], 'yes');
        expect(response.headers['content-type'], contains('application/json'));
        expect(networkCalls, 0);
        expect(sender.sent[0].body['isMocked'], true);
        expect(sender.sent[1].body['isMocked'], true);
        expect(sender.sent[1].body['responseHttpCode'], 201);
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
            'response': {'httpCode': 500, 'delay': 0},
          },
        ]),
      );
      expect((await client.get(Uri.parse('https://x.test/a'))).body, 'real');
      expect(networkCalls, 1);
      expect(sender.sent[0].body['isMocked'], false);
    });

    test('an exception mock throws and is logged', () async {
      plugin.onMessageReceived(
        setup('setup_mocks', [
          {
            'expectation': {'urlPattern': '.*', 'method': '*'},
            'response': {
              'errorException': 'java.net.ConnectException',
              'delay': 0,
            },
          },
        ]),
      );
      await expectLater(
        client.get(Uri.parse('https://x.test/a')),
        throwsA(isA<http.ClientException>()),
      );
      expect(sender.sent[1].body['responseError'], 'java.net.ConnectException');
      expect(networkCalls, 0);
    });

    test('a timeout exception mock throws a TimeoutException', () async {
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
        client.get(Uri.parse('https://x.test/a')),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      'a bad network error rate of 1 returns the configured error, not flagged as mocked',
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
        final response = await client.get(Uri.parse('https://x.test/a'));
        expect((response.statusCode, response.body), (503, 'down'));
        expect(networkCalls, 0);
        expect(sender.sent[1].body['isMocked'], false);
      },
    );
  });
}
