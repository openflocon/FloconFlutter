import 'dart:async';

import '../core/logger.dart';
import 'socket_connection.dart';
import 'socket_connection_io.dart'
    if (dart.library.js_interop) 'socket_connection_web.dart';

/// A `wss://` connection to the desktop app.
///
/// The desktop serves a self-signed certificate: the connection is encrypted, but with `dart:io` the certificate
/// is not verified (so the app needs no cleartext traffic nor App Transport Security exception).
class FloconWebSocketClient {
  FloconSocketConnection? _socket;

  bool get isConnected => _socket != null;

  /// Opens the connection. Throws if the desktop is unreachable.
  Future<void> connect(
    Uri uri, {
    required void Function(String) onMessageReceived,
    required void Function() onClosed,
  }) async {
    if (_socket != null) return;
    final socket = await openSocketConnection(uri);
    _socket = socket;
    FloconLogger.log('WebSocket opened on $uri');
    socket.listen(
      onMessage: onMessageReceived,
      onClosed: (error) {
        if (error != null) FloconLogger.logError('WebSocket error', error);
        // already handled, or explicit disconnect
        if (!identical(_socket, socket)) return;
        _socket = null;
        onClosed();
      },
    );
  }

  /// Returns false if the message could not be sent.
  bool send(String message) {
    final socket = _socket;
    if (socket == null) return false;
    try {
      socket.send(message);
      return true;
    } catch (e) {
      FloconLogger.logError('send failed', e);
      return false;
    }
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null; // before closing, so that onClosed is not triggered
    await socket?.close();
  }
}
