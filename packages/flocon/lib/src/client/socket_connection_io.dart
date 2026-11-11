import 'dart:async';
import 'dart:io';

import 'socket_connection.dart';

/// Opens a `wss://` connection with `dart:io`. The desktop serves a self-signed certificate: it is accepted
/// without being verified.
Future<FloconSocketConnection> openSocketConnection(Uri uri) async {
  final client = HttpClient()..badCertificateCallback = (_, __, ___) => true;
  try {
    final socket = await WebSocket.connect(
      uri.toString(),
      headers: {'User-Agent': 'Flocon'},
      customClient: client,
    ).timeout(const Duration(seconds: 5));
    return _IoSocketConnection(socket, client);
  } catch (_) {
    client.close(force: true);
    rethrow;
  }
}

class _IoSocketConnection implements FloconSocketConnection {
  _IoSocketConnection(this._socket, this._client);

  final WebSocket _socket;
  final HttpClient _client;

  @override
  void send(String message) => _socket.add(message);

  @override
  void listen({
    required void Function(String) onMessage,
    required void Function(Object? error) onClosed,
  }) {
    _socket.listen(
      (data) {
        if (data is String) onMessage(data);
      },
      onDone: () {
        _client.close(force: true);
        onClosed(null);
      },
      onError: (Object e) {
        _client.close(force: true);
        onClosed(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Future<void> close() async {
    _client.close(force: true);
    await _socket.close();
  }
}
