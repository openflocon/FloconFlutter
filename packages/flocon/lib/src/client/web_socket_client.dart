import 'dart:async';
import 'dart:io';

import '../core/logger.dart';

/// A `wss://` connection to the desktop app.
///
/// The desktop serves a self-signed certificate: the connection is encrypted, but the certificate is
/// not verified (so the app needs no cleartext traffic nor App Transport Security exception).
class FloconWebSocketClient {
  WebSocket? _socket;

  bool get isConnected => _socket != null;

  /// Opens the connection. Throws if the desktop is unreachable.
  Future<void> connect(
    Uri uri, {
    required void Function(String) onMessageReceived,
    required void Function() onClosed,
  }) async {
    if (_socket != null) return;
    final client = HttpClient()..badCertificateCallback = (_, __, ___) => true;
    final WebSocket socket;
    try {
      socket = await WebSocket.connect(
        uri.toString(),
        headers: {'User-Agent': 'Flocon'},
        customClient: client,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      client.close(force: true);
      rethrow;
    }
    _socket = socket;
    FloconLogger.log('WebSocket opened on $uri');
    socket.listen(
      (data) {
        if (data is String) onMessageReceived(data);
      },
      onDone: () => _ended(socket, client, onClosed),
      onError: (Object e) {
        FloconLogger.logError('WebSocket error', e);
        _ended(socket, client, onClosed);
      },
      cancelOnError: true,
    );
  }

  void _ended(WebSocket socket, HttpClient client, void Function() onClosed) {
    client.close(force: true);
    // already handled, or explicit disconnect
    if (!identical(_socket, socket)) return;
    _socket = null;
    onClosed();
  }

  /// Returns false if the message could not be sent.
  bool send(String message) {
    final socket = _socket;
    if (socket == null) return false;
    try {
      socket.add(message);
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
