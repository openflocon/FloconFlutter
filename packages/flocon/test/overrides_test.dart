import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flocon/flocon.dart';
import 'package:flocon/src/plugins/network/network_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) {}
}

/// Returns the given values in a loop.
class _FakeRandom implements Random {
  _FakeRandom(this.doubles, [this.ints = const [0]]);
  final List<double> doubles;
  final List<int> ints;
  var _d = 0, _i = 0;
  @override
  double nextDouble() => doubles[_d++ % doubles.length];
  @override
  int nextInt(int max) => ints[_i++ % ints.length] % max;
  @override
  bool nextBool() => false;
}

FloconMessageFromServer _msg(String method, Object body) =>
    FloconMessageFromServer(
      plugin: 'network',
      method: method,
      body: jsonEncode(body),
    );

Map<String, Object?> _mock(
  String pattern,
  String method,
  Map<String, Object?> response,
) => {
  'expectation': {'urlPattern': pattern, 'method': method},
  'response': response,
};

void main() {
  late FloconNetworkPlugin plugin;
  final delays = <Duration>[];

  FloconNetworkPlugin build([Random? random]) => FloconNetworkPlugin(
    sender: _Sender(),
    random: random,
    delay: (d) async => delays.add(d),
  );

  setUp(() {
    delays.clear();
    plugin = build();
  });

  group('mocks', () {
    test(
      'setupMocks parses body mocks and error mocks, ignoring invalid entries',
      () {
        plugin.onMessageReceived(
          _msg('setup_mocks', [
            _mock(r'https://x\.test/a', 'GET', {
              'httpCode': 201,
              'body': '{}',
              'mediaType': 'application/json',
              'delay': 50,
              'headers': {'x': '1'},
            }),
            _mock('.*', '*', {
              'errorException': 'java.net.SocketTimeoutException',
              'delay': 0,
            }),
            _mock('.*', '*', {}), // neither a code nor an exception: dropped
          ]),
        );
        expect(plugin.mocks, hasLength(2));
        final response = plugin.mocks.first.toOverride() as FloconFakeResponse;
        expect(
          (response.statusCode, response.body, response.isMocked),
          (201, '{}', true),
        );
        expect(response.headersWithContentType, {
          'x': '1',
          'content-type': 'application/json',
        });
        expect(
          (plugin.mocks.last.toOverride() as FloconFakeError).kind,
          FloconErrorKind.timeout,
        );
      },
    );

    test('unreadable setupMocks gives no mock', () {
      plugin.onMessageReceived(
        const FloconMessageFromServer(
          plugin: 'network',
          method: 'setup_mocks',
          body: 'nope',
        ),
      );
      expect(plugin.mocks, isEmpty);
    });

    test(
      'the url pattern must match the whole url, the method is case-insensitive or a wildcard',
      () {
        const mock = FloconMock(
          urlPattern: r'https://x\.test/users/\d+',
          method: 'get',
          delay: Duration.zero,
          httpCode: 200,
        );
        expect(mock.matches('https://x.test/users/42', 'GET'), isTrue);
        expect(mock.matches('https://x.test/users/42/posts', 'GET'), isFalse);
        expect(mock.matches('https://x.test/users/42', 'POST'), isFalse);
        expect(
          const FloconMock(
            urlPattern: '.*',
            method: '*',
            delay: Duration.zero,
            httpCode: 200,
          ).matches('https://a', 'DELETE'),
          isTrue,
        );
        expect(
          const FloconMock(
            urlPattern: '(',
            method: '*',
            delay: Duration.zero,
            httpCode: 200,
          ).matches('(', 'GET'),
          isFalse,
        );
      },
    );

    test(
      'findMock returns the first match, applyOverride waits for the delay',
      () async {
        plugin.mocks = [
          const FloconMock(
            urlPattern: 'https://x/a',
            method: '*',
            delay: Duration(milliseconds: 200),
            httpCode: 200,
            body: 'first',
          ),
          const FloconMock(
            urlPattern: 'https://x/.*',
            method: '*',
            delay: Duration.zero,
            httpCode: 500,
            body: 'second',
          ),
        ];
        final mock = plugin.findMock('https://x/a', 'GET');
        final override = await plugin.applyOverride(mock) as FloconFakeResponse;
        expect(override.body, 'first');
        expect(delays, [const Duration(milliseconds: 200)]);
        expect(plugin.findMock('https://y/', 'GET'), isNull);
      },
    );
  });

  group('bad network', () {
    Map<String, Object?> config({
      double latency = 1,
      double errors = 1,
      List<Map<String, Object?>>? list,
    }) => {
      'latency': {
        'latencyTriggerProbability': latency,
        'minLatencyMs': 100,
        'maxLatencyMs': 300,
      },
      'errorProbability': errors,
      'errors':
          list ??
          [
            {
              'weight': 1.0,
              'errorCode': 503,
              'errorBody': 'down',
              'errorContentType': 'text/plain',
            },
            {'weight': 3.0, 'errorException': 'java.net.UnknownHostException'},
          ],
    };

    test('no configuration lets the call through', () async {
      expect(await plugin.applyOverride(null), isNull);
    });

    test(
      'latency is applied within the configured bounds, then the call goes through',
      () async {
        plugin = build(_FakeRandom([0.5], [50]));
        plugin.onMessageReceived(
          _msg('setup_bad_network_config', config(errors: 0)),
        );
        expect(await plugin.applyOverride(null), isNull);
        expect(delays, [const Duration(milliseconds: 150)]);
      },
    );

    test('no latency when the trigger probability is 0', () async {
      plugin.onMessageReceived(
        _msg('setup_bad_network_config', config(latency: 0, errors: 0)),
      );
      await plugin.applyOverride(null);
      expect(delays, isEmpty);
    });

    test('errors are picked by weight and are not flagged as mocked', () async {
      plugin.onMessageReceived(
        _msg('setup_bad_network_config', config(latency: 0)),
      );
      // total weight 4: a pick of 0.1 * 4 = 0.4 falls in the first error, 0.9 * 4 = 3.6 in the second
      plugin = build(_FakeRandom([0.0, 0.1, 0.0, 0.9]));
      plugin.badQualityConfig = parseBadQualityConfig(
        jsonEncode(config(latency: 0)),
      );
      final first = await plugin.applyOverride(null) as FloconFakeResponse;
      expect(
        (first.statusCode, first.body, first.isMocked),
        (503, 'down', false),
      );
      final second = await plugin.applyOverride(null) as FloconFakeError;
      expect(
        (second.kind, second.isMocked),
        (FloconErrorKind.connection, false),
      );
    });

    test('a mock wins over the bad network simulation', () async {
      plugin.onMessageReceived(_msg('setup_bad_network_config', config()));
      plugin.mocks = [
        const FloconMock(
          urlPattern: '.*',
          method: '*',
          delay: Duration.zero,
          httpCode: 200,
          body: 'ok',
        ),
      ];
      final override =
          await plugin.applyOverride(plugin.findMock('https://x', 'GET'))
              as FloconFakeResponse;
      expect((override.body, override.isMocked), ('ok', true));
      expect(delays, isEmpty);
    });

    test('unreadable configuration disables the simulation', () {
      plugin.onMessageReceived(_msg('setup_bad_network_config', config()));
      plugin.onMessageReceived(
        const FloconMessageFromServer(
          plugin: 'network',
          method: 'setup_bad_network_config',
          body: '{}',
        ),
      );
      expect(plugin.badQualityConfig, isNull);
    });
  });

  test('error kinds', () {
    expect(
      floconErrorKindOf('java.net.SocketTimeoutException'),
      FloconErrorKind.timeout,
    );
    expect(
      floconErrorKindOf('java.net.ConnectException'),
      FloconErrorKind.connection,
    );
    expect(
      floconErrorKindOf('java.lang.IllegalStateException'),
      FloconErrorKind.unknown,
    );
  });

  persistenceTests();
}

void persistenceTests() {
  group('persistence', () {
    late Directory dir;
    late FloconNetworkStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('flocon_network');
      store = FloconNetworkStore(() async => dir);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    FloconNetworkPlugin build() =>
        FloconNetworkPlugin(sender: _Sender(), store: store);

    test('the mocks and the bad network configuration come back at the next launch', () async {
      final first = build();
      first.onMessageReceived(_msg('setup_mocks', [
        _mock('https://x/.*', 'GET', {'httpCode': 200, 'body': 'saved'}),
      ]));
      first.onMessageReceived(_msg('setup_bad_network_config', {
        'latency': {'latencyTriggerProbability': 1, 'minLatencyMs': 1, 'maxLatencyMs': 2},
        'errorProbability': 0,
        'errors': <Object>[],
      }));
      // let the writes finish
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final second = build();
      await second.ready;
      expect(second.mocks.single.body, 'saved');
      expect(second.badQualityConfig!.maxLatencyMs, 2);
      expect(second.findMock('https://x/a', 'GET'), isNotNull);
    });

    test('what the desktop sends replaces what was saved, an empty list clears the mocks', () async {
      final first = build();
      first.onMessageReceived(_msg('setup_mocks', [
        _mock('.*', '*', {'httpCode': 200}),
      ]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      first.onMessageReceived(_msg('setup_mocks', <Object>[]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = build();
      await second.ready;
      expect(second.mocks, isEmpty);
    });

    test('an unreadable bad network configuration is not kept', () async {
      final first = build();
      first.onMessageReceived(_msg('setup_bad_network_config', {
        'latency': {'latencyTriggerProbability': 1, 'minLatencyMs': 1, 'maxLatencyMs': 2},
        'errorProbability': 0,
        'errors': <Object>[],
      }));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      first.onMessageReceived(const FloconMessageFromServer(plugin: 'network', method: 'setup_bad_network_config', body: '{}'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = build();
      await second.ready;
      expect(second.badQualityConfig, isNull);
    });

    test('a broken file gives no configuration', () async {
      Directory('${dir.path}/network').createSync();
      File('${dir.path}/network/flocon_network_mocks.json').writeAsStringSync('nope');
      final plugin = build();
      await plugin.ready;
      expect(plugin.mocks, isEmpty);
    });
  });
}
