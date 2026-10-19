import 'dart:convert';
import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, List<dynamic> body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as List<dynamic>));
}

void main() {
  late Directory dir;
  late _Sender sender;
  late FloconCrashStore store;
  var connected = false;
  late FloconCrashReporterPlugin plugin;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('flocon_crashes');
    sender = _Sender();
    store = FloconCrashStore(dir);
    connected = false;
    plugin = FloconCrashReporterPlugin(sender: sender, store: store, isConnected: () => connected);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('a crash while disconnected is saved on disk, not sent', () {
    plugin.recordError(StateError('boom'), StackTrace.fromString('#0 main'));
    expect(sender.sent, isEmpty);
    final pending = store.pendingReports();
    expect(pending.single.exceptionType, 'StateError');
    expect(pending.single.exceptionMessage, contains('boom'));
    expect(pending.single.stackTrace, '#0 main');
  });

  test('pending crashes are sent as one JSON array on connection, then deleted', () {
    plugin.recordError(StateError('first'), null);
    plugin.recordError(ArgumentError('second'), null);
    plugin.onConnectedToServer();
    final message = sender.sent.single;
    expect((message.plugin, message.method), ('crashreporter', 'reportcrash'));
    expect(message.body, hasLength(2));
    expect(message.body.first.keys.toSet(),
        {'crashId', 'timestamp', 'exceptionType', 'exceptionMessage', 'stackTrace'});
    expect(store.pendingReports(), isEmpty);
  });

  test('a crash while connected is sent right away', () {
    connected = true;
    plugin.recordError(Exception('now'), null);
    expect(sender.sent.single.body.single['exceptionMessage'], contains('now'));
    expect(store.pendingReports(), isEmpty);
  });

  test('nothing is sent when there is no pending crash; broken files are skipped', () {
    File('${dir.path}/broken.json').writeAsStringSync('{not json');
    plugin.onConnectedToServer();
    expect(sender.sent, isEmpty);
  });

  test('the Flutter and platform handlers report, then chain the previous ones', () {
    final originalFlutter = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    var previousFlutterCalled = false;
    var previousPlatformCalled = false;
    FlutterError.onError = (_) => previousFlutterCalled = true;
    PlatformDispatcher.instance.onError = (_, __) => previousPlatformCalled = true;
    addTearDown(() {
      FlutterError.onError = originalFlutter;
      PlatformDispatcher.instance.onError = originalPlatform;
    });

    installFloconCrashHandlers(plugin);
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('framework'), stack: StackTrace.current));
    final handled = PlatformDispatcher.instance.onError!(StateError('async'), StackTrace.current);

    expect(previousFlutterCalled, isTrue);
    expect(previousPlatformCalled, isTrue);
    expect(handled, isTrue);
    final messages = store.pendingReports().map((r) => r.exceptionMessage).join('|');
    expect(messages, allOf(contains('framework'), contains('async')));
  });

  test('enabling is a no-op before Flocon.initialize', () async {
    await floconEnableCrashReporter(storeDirectory: dir);
    expect(Flocon.plugin<FloconCrashReporterPlugin>(), isNull);
  });
}
