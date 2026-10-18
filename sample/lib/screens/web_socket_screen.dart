import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import 'actions_view.dart';

/// WebSockets cannot be intercepted automatically: log each event with floconLogWebSocketEvent.
class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key});

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  static const _wsUrl = 'wss://echo.websocket.events';
  WebSocket? _socket;

  void _log(FloconWebSocketEventType type, {String? message, Object? error}) => floconLogWebSocketEvent(
      FloconWebSocketEvent(websocketUrl: _wsUrl, event: type, message: message, error: error));

  Future<String> _open() async {
    final socket = await WebSocket.connect(_wsUrl);
    _socket = socket;
    _log(FloconWebSocketEventType.open);
    socket.listen(
      (m) => _log(FloconWebSocketEventType.receiveMessage, message: m.toString()),
      onError: (Object e) => _log(FloconWebSocketEventType.error, error: e),
      onDone: () => _log(FloconWebSocketEventType.closed),
    );
    return 'open';
  }

  Future<String> _send() async {
    const text = 'hello from Flocon';
    _socket?.add(text);
    _log(FloconWebSocketEventType.sendMessage, message: text);
    return _socket == null ? 'not open' : 'sent';
  }

  Future<String> _close() async {
    _log(FloconWebSocketEventType.closing);
    await _socket?.close();
    _socket = null;
    return 'closed';
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('WebSocket')),
        body: ActionsView(actions: [
          SampleAction('Open', _open),
          SampleAction('Send message', _send),
          SampleAction('Close', _close),
        ]),
      );
}
