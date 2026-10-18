import 'dart:async';
import 'dart:io';

import '../core/logger.dart';

/// Minimal WebSocket client with a bounded queue for messages sent while disconnected.
class FloconWebSocketClient {
  FloconWebSocketClient({this.queueCapacity = 200});

  final int queueCapacity;
  final List<String> _queue = [];
  WebSocket? _socket;

  bool get isConnected => _socket != null;

  /// Opens the connection. Throws if the desktop is unreachable.
  Future<void> connect({
    required String address,
    required int port,
    required void Function(String) onMessageReceived,
    required void Function() onClosed,
  }) async {
    if (_socket != null) return;
    final socket = await WebSocket.connect(
      'ws://$address:$port',
      headers: {'User-Agent': 'Flocon'},
    ).timeout(const Duration(seconds: 5));
    _socket = socket;
    FloconLogger.log('WebSocket opened');
    socket.listen(
      (data) {
        if (data is String) onMessageReceived(data);
      },
      onDone: () => _ended(socket, onClosed),
      onError: (Object e) {
        FloconLogger.logError('WebSocket error', e);
        _ended(socket, onClosed);
      },
      cancelOnError: true,
    );
  }

  void _ended(WebSocket socket, void Function() onClosed) {
    if (!identical(_socket, socket)) return; // already handled or explicit disconnect
    _socket = null;
    onClosed();
  }

  /// Sends the message, or queues it when disconnected (oldest dropped past the capacity).
  void send(String message) {
    final socket = _socket;
    if (socket == null) {
      _queue.add(message);
      if (_queue.length > queueCapacity) {
        _queue.removeRange(0, _queue.length - queueCapacity);
      }
      return;
    }
    socket.add(message);
  }

  void sendPendingMessages() {
    if (_socket == null) return;
    final pending = List<String>.of(_queue);
    _queue.clear();
    pending.forEach(send);
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null; // before closing so onClosed is not triggered
    await socket?.close();
  }
}
