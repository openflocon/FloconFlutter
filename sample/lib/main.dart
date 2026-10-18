import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Android emulator reaches the host machine through 10.0.2.2.
  // On a physical device, use the local IP of the computer running Flocon.
  Flocon.initialize(
    config: FloconConfig(host: Platform.isAndroid ? '10.0.2.2' : 'localhost'),
  );
  runApp(const SampleApp());
}

final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
  ..interceptors.add(FloconDioInterceptor());

final httpClient = FloconHttpClient(http.Client());

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flocon Sample',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Tap a button, then look at the Flocon desktop app';
  WebSocket? _socket;
  static const _wsUrl = 'wss://echo.websocket.events';

  Future<void> _run(String label, Future<Response<dynamic>> Function() call) async {
    setState(() => _status = '$label…');
    try {
      final r = await call();
      setState(() => _status = '$label → ${r.statusCode}');
    } on DioException catch (e) {
      setState(() => _status = '$label → ${e.response?.statusCode ?? e.type.name}');
    }
  }

  Future<void> _runHttp(String label, Future<http.Response> Function() call) async {
    setState(() => _status = '$label…');
    try {
      final r = await call();
      setState(() => _status = '$label → ${r.statusCode}');
    } catch (e) {
      setState(() => _status = '$label → $e');
    }
  }

  Future<void> _openSocket() async {
    try {
      final socket = await WebSocket.connect(_wsUrl);
      _socket = socket;
      floconLogWebSocketEvent(
          FloconWebSocketEvent(websocketUrl: _wsUrl, event: FloconWebSocketEventType.open));
      socket.listen(
        (m) => floconLogWebSocketEvent(FloconWebSocketEvent(
            websocketUrl: _wsUrl,
            event: FloconWebSocketEventType.receiveMessage,
            message: m.toString())),
        onError: (Object e) => floconLogWebSocketEvent(FloconWebSocketEvent(
            websocketUrl: _wsUrl, event: FloconWebSocketEventType.error, error: e)),
        onDone: () => floconLogWebSocketEvent(
            FloconWebSocketEvent(websocketUrl: _wsUrl, event: FloconWebSocketEventType.closed)),
      );
      setState(() => _status = 'WebSocket open');
    } catch (e) {
      setState(() => _status = 'WebSocket failed: $e');
    }
  }

  void _sendSocket() {
    final socket = _socket;
    if (socket == null) return;
    const text = 'hello from Flocon';
    socket.add(text);
    floconLogWebSocketEvent(FloconWebSocketEvent(
        websocketUrl: _wsUrl, event: FloconWebSocketEventType.sendMessage, message: text));
  }

  Future<void> _closeSocket() async {
    floconLogWebSocketEvent(
        FloconWebSocketEvent(websocketUrl: _wsUrl, event: FloconWebSocketEventType.closing));
    await _socket?.close();
    _socket = null;
    setState(() => _status = 'WebSocket closed');
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(String, VoidCallback)>[
      ('GET /posts/1', () => _run('GET', () => dio.get('/posts/1'))),
      ('GET /posts (list)', () => _run('GET list', () => dio.get('/posts', queryParameters: {'userId': 1}))),
      ('POST /posts (JSON)', () => _run('POST', () => dio.post('/posts', data: {'title': 'foo', 'body': 'bar', 'userId': 1}))),
      ('PUT /posts/1', () => _run('PUT', () => dio.put('/posts/1', data: {'id': 1, 'title': 'updated'}))),
      ('DELETE /posts/1', () => _run('DELETE', () => dio.delete('/posts/1'))),
      ('404 not found', () => _run('404', () => dio.get('/does-not-exist'))),
      ('500 server error', () => _run('500', () => dio.get('https://httpbin.org/status/500'))),
      ('Network error', () => _run('Network error', () => dio.get('https://does-not-exist.invalid/'))),
      ('Slow request (3s)', () => _run('Slow', () => dio.get('https://httpbin.org/delay/3'))),
      ('Image download', () => _run('Image', () => dio.get('https://httpbin.org/image/png', options: Options(responseType: ResponseType.bytes)))),
      ('FormData upload', () => _run('FormData', () => dio.post('https://httpbin.org/post', data: FormData.fromMap({'name': 'flocon', 'file': MultipartFile.fromString('hello', filename: 'hello.txt')})))),
      ('http: GET /todos/1', () => _runHttp('http GET', () => httpClient.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1')))),
      ('http: POST /posts', () => _runHttp('http POST', () => httpClient.post(Uri.parse('https://jsonplaceholder.typicode.com/posts'), headers: {'content-type': 'application/json'}, body: '{"title":"from http"}'))),
      ('http: 404', () => _runHttp('http 404', () => httpClient.get(Uri.parse('https://jsonplaceholder.typicode.com/nope')))),
      ('Analytics: log events', () {
        floconAnalytics('firebase').logEvents([
          AnalyticsEvent(eventName: 'button_clicked', properties: [AnalyticsProperty('button_id', 'sample'), AnalyticsProperty('at', DateTime.now().toIso8601String())]),
        ]);
        setState(() => _status = 'Analytics event sent');
      }),
      ('Table: log row', () {
        floconTable('users').log([TableColumnConfig('name', 'Florent'), TableColumnConfig('age', '33')]);
        setState(() => _status = 'Table row sent');
      }),
      ('WebSocket: open', _openSocket),
      ('WebSocket: send', _sendSocket),
      ('WebSocket: close', _closeSocket),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Flocon Flutter sample')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(_status)),
        Expanded(
          child: ListView(
            children: [
              for (final (label, onTap) in actions)
                ListTile(title: Text(label), trailing: const Icon(Icons.play_arrow), onTap: onTap),
            ],
          ),
        ),
      ]),
    );
  }
}
