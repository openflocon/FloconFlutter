import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A fake Flocon desktop: a `wss://` server with a self-signed certificate, recording the messages it receives.
class DesktopStub {
  DesktopStub._(this._server);

  final HttpServer _server;
  final sockets = <WebSocket>[];
  final received = <Map<String, dynamic>>[];
  final _waiters = <Completer<void>>[];
  int connections = 0;

  int get port => _server.port;

  static Future<DesktopStub> start({int port = 0}) async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/test_cert.pem')
      ..usePrivateKey('test/fixtures/test_key.pem');
    final stub = DesktopStub._(
      await HttpServer.bindSecure('localhost', port, context),
    );
    stub._server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      stub.connections++;
      stub.sockets.add(socket);
      socket.listen((data) {
        stub.received.add(jsonDecode(data as String) as Map<String, dynamic>);
        for (final w in stub._waiters.toList()) {
          if (!w.isCompleted) w.complete();
        }
      });
    });
    return stub;
  }

  /// Waits until [count] messages were received.
  Future<void> waitForMessages(
    int count, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (received.length < count) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) {
        throw TimeoutException(
          'Received ${received.length}/$count messages: $received',
        );
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future.timeout(remaining, onTimeout: () {});
      _waiters.remove(waiter);
    }
  }

  /// `plugin.method` of the messages received.
  List<String> get names => [
    for (final m in received) '${m['plugin']}.${m['method']}',
  ];

  void send(String plugin, String method, [String body = '']) => sockets.last
      .add(jsonEncode({'plugin': plugin, 'method': method, 'body': body}));

  /// Closes the connection from the desktop side.
  Future<void> dropConnections() async {
    for (final s in sockets) {
      await s.close();
    }
    sockets.clear();
  }

  Future<void> stop() async {
    await dropConnections();
    await _server.close(force: true);
  }
}
