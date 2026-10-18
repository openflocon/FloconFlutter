import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import 'actions_view.dart';
import 'dio_screen.dart';
import 'http_screen.dart';
import 'image_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Text('Flocon Flutter sample')),
      body: ListView(children: [
        ListTile(leading: const Icon(Icons.cloud_outlined), title: const Text('Dio'), subtitle: const Text('HTTP calls with FloconDioInterceptor'), onTap: () => open(const DioScreen())),
        ListTile(leading: const Icon(Icons.http), title: const Text('package:http'), subtitle: const Text('HTTP calls with FloconHttpClient'), onTap: () => open(const HttpScreen())),
        ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Images'), subtitle: const Text('Download and display images'), onTap: () => open(const ImageScreen())),
        ListTile(leading: const Icon(Icons.sync_alt), title: const Text('WebSocket, Analytics, Tables'), onTap: () => open(const OtherScreen())),
      ]),
    );
  }
}

/// WebSocket events (manual logging), analytics events and table rows.
class OtherScreen extends StatefulWidget {
  const OtherScreen({super.key});

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
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
        appBar: AppBar(title: const Text('WebSocket, Analytics, Tables')),
        body: ActionsView(actions: [
          SampleAction('WebSocket: open', _open),
          SampleAction('WebSocket: send', _send),
          SampleAction('WebSocket: close', _close),
          SampleAction('Analytics: log event', () async {
            floconAnalytics('firebase').logEvents([
              AnalyticsEvent(eventName: 'button_clicked', properties: [
                const AnalyticsProperty('button_id', 'sample'),
                AnalyticsProperty('at', DateTime.now().toIso8601String()),
              ]),
            ]);
            return 'sent';
          }),
          SampleAction('Table: log row', () async {
            floconTable('users').log([const TableColumnConfig('name', 'Florent'), const TableColumnConfig('age', '33')]);
            return 'sent';
          }),
        ]),
      );
}
