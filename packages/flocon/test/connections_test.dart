import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flocon/src/client/address_store.dart';
import 'package:flocon/src/client/connections.dart';
import 'package:flocon/src/client/flocon_client.dart';
import 'package:flocon/src/core/app_infos.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/desktop_stub.dart';

class _MemoryStore implements FloconAddressStore {
  String? address;
  @override
  Future<String?> load() async => address;
  @override
  Future<void> save(String address) async => this.address = address;
  @override
  Future<void> clear() async => address = null;
}

class _Echo implements FloconPlugin {
  final messages = <FloconMessageFromServer>[];
  @override
  String get pluginName => 'echo';
  @override
  void onConnectedToServer() {}
  @override
  void onMessageReceived(FloconMessageFromServer message) =>
      messages.add(message);
}

Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late DesktopStub desktop;
  late DesktopStub second;
  late FloconClient client;
  late FloconConnections connections;
  late FloconConnectionStateStore states;
  late _MemoryStore store;

  Future<void> boot({
    String? additionalAddress,
    String? remembered,
    int? port,
  }) async {
    final config = FloconConfig(
      host: 'localhost',
      webSocketPort: port ?? desktop.port,
      httpPort: 1,
      additionalAddress: additionalAddress,
    );
    client = FloconClient(
      config,
      appInfos: Future.value(
        const FloconAppInfos(
          deviceId: 'dev',
          deviceName: 'phone',
          platform: 'ios',
          appName: 'App',
          appPackageName: 'io.app',
        ),
      ),
      appIcon: () async => 'ICON',
    );
    states = FloconConnectionStateStore();
    store = _MemoryStore()..address = remembered;
    connections = FloconConnections(
      client: client,
      states: states,
      config: client.config,
      addressStore: store,
      retryDelay: const Duration(milliseconds: 50),
    );
    await connections.start();
  }

  setUp(() async {
    desktop = await DesktopStub.start();
    second = await DesktopStub.start();
  });
  tearDown(() async {
    await client.removeExtraLink(client.defaultLink);
    final extra = client.extraLink;
    if (extra != null) await client.removeExtraLink(extra);
    await desktop.stop();
    await second.stop();
  });

  test(
    'connects over wss with the self-signed certificate, introduces the app, '
    'then sends what was kept',
    () async {
      await boot();
      client
        ..send(plugin: 'table', method: 'add_items', body: '[]')
        ..send(plugin: 'analytics', method: 'add_items', body: '[]');
      await desktop.waitForMessages(3);

      expect(desktop.names, [
        'bonjour.bonjour',
        'table.add_items',
        'analytics.add_items',
      ]);
      final hello = desktop.received.first;
      expect(jsonDecode(hello['body'] as String), {'sdk': 'flutter', 'connectionType': 'default'});
      expect(hello.keys.toSet(), {
        'deviceId',
        'plugin',
        'body',
        'appName',
        'appPackageName',
        'method',
        'deviceName',
        'appInstance',
        'platform',
        'versionName',
      });
      expect(
        (
          hello['deviceId'],
          hello['appName'],
          hello['appPackageName'],
          hello['platform'],
        ),
        ('dev', 'App', 'io.app', 'ios'),
      );
      expect(states.state, isA<FloconConnected>());
      expect(client.isConnected, isTrue);
    },
  );

  test(
    'keeps trying until the desktop is reachable, keeping what was logged',
    () async {
      final port = desktop.port;
      await desktop.stop();
      await boot(port: port);
      client.send(plugin: 'table', method: 'add_items', body: '[1]');
      await until(() => states.state is FloconFailed);
      expect(client.outbox.bufferedCount, 1);

      desktop = await DesktopStub.start(port: port);
      await desktop.waitForMessages(2);
      expect(desktop.names, ['bonjour.bonjour', 'table.add_items']);
      expect(states.state, isA<FloconConnected>());
    },
  );

  test(
    'reconnects when the connection is lost and sends what was logged meanwhile',
    () async {
      await boot();
      await desktop.waitForMessages(1);
      await desktop.dropConnections();
      await until(() => !client.isConnected);
      client.send(plugin: 'table', method: 'add_items', body: '[2]');
      await desktop.waitForMessages(3);
      expect(desktop.names, [
        'bonjour.bonjour',
        'bonjour.bonjour',
        'table.add_items',
      ]);
      expect(states.state, isA<FloconConnected>());
    },
  );

  test('routes the desktop messages to the plugin, whatever the case', () async {
    await boot();
    final echo = _Echo();
    client.register(echo);
    await desktop.waitForMessages(1);
    desktop.send('Echo', 'do_it', '{"a":1}');
    await until(() => echo.messages.isNotEmpty);
    expect((echo.messages.single.method, echo.messages.single.body), (
      'do_it',
      '{"a":1}',
    ));
  });

  test('answers get_app_icon by itself', () async {
    await boot();
    await desktop.waitForMessages(1);
    desktop.send('device', 'get_app_icon');
    await desktop.waitForMessages(2);
    expect(desktop.names.last, 'device.app_icon');
    expect(desktop.received.last['body'], 'ICON');
  });

  group('connect(address)', () {
    test('adds an address as wifi, both desktops then get the messages', () async {
      await boot();
      await desktop.waitForMessages(1);

      final result = await connections.connect('localhost:${second.port}:1');
      expect(result, isA<FloconConnectResultConnected>());
      await second.waitForMessages(1);
      expect(second.names, ['bonjour.bonjour']);
      expect(jsonDecode(second.received.first['body'] as String), {
        'sdk': 'flutter',
        'connectionType': 'wifi',
      });
      client.send(plugin: 'table', method: 'add_items', body: '[4]');
      await Future.wait([desktop.waitForMessages(2), second.waitForMessages(2)]);
      expect(desktop.received.last['body'], '[4]');
      expect(second.received.last['body'], '[4]');
      expect(store.address, 'localhost:${second.port}:1');
    });

    test('reports an invalid or unreachable address instead of throwing', () async {
      await boot();
      expect(
        await connections.connect('http://x'),
        isA<FloconConnectResultInvalidAddress>(),
      );
      expect(
        await connections.connect('localhost:1:2'),
        isA<FloconConnectResultFailed>(),
      );
      expect(client.extraLink, isNull);
      await until(() => client.defaultLink.isConnected);
    });

    test('the default address is not added twice', () async {
      await boot();
      await until(() => client.defaultLink.isConnected);
      expect(
        await connections.connect('localhost:${desktop.port}:1'),
        isA<FloconConnectResultConnected>(),
      );
      expect(client.extraLink, isNull);
    });

    test('disconnect closes the added connection and forgets its address', () async {
      await boot();
      await connections.connect('localhost:${second.port}:1');
      expect(client.extraLink, isNotNull);
      await connections.disconnect();
      expect(client.extraLink, isNull);
      expect(store.address, isNull);
      await until(() => client.defaultLink.isConnected);
    });

    test('the last address comes back at the next launch and wins', () async {
      await boot(
        remembered: 'localhost:${second.port}:1',
        additionalAddress: 'localhost:1:1',
      );
      await second.waitForMessages(1);
      expect(jsonDecode(second.received.first['body'] as String), {
        'sdk': 'flutter',
        'connectionType': 'wifi',
      });
      expect(client.extraLink!.address.webSocketPort, second.port);
    });
  });

  test('the connection states start with the current one', () async {
    await boot();
    final seen = <Type>[];
    final sub = states.stream.listen((s) => seen.add(s.runtimeType));
    await until(() => seen.contains(FloconConnected));
    await sub.cancel();
    expect(seen.last, FloconConnected);
  });
}
