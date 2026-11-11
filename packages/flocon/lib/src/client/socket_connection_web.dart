import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'socket_connection.dart';

/// Opens a `wss://` connection with the browser WebSocket. A browser cannot skip the verification of the
/// self-signed certificate of the desktop: the connection only succeeds once the browser trusts it.
Future<FloconSocketConnection> openSocketConnection(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  try {
    await channel.ready.timeout(const Duration(seconds: 5));
  } catch (_) {
    unawaited(channel.sink.close().catchError((_) {}));
    rethrow;
  }
  return _WebSocketConnection(channel);
}

class _WebSocketConnection implements FloconSocketConnection {
  _WebSocketConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  void listen({
    required void Function(String) onMessage,
    required void Function(Object? error) onClosed,
  }) {
    _channel.stream.listen(
      (data) {
        if (data is String) onMessage(data);
      },
      onDone: () => onClosed(null),
      onError: (Object e) => onClosed(e),
      cancelOnError: true,
    );
  }

  @override
  Future<void> close() => _channel.sink.close();
}
