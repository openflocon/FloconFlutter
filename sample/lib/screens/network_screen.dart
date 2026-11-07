import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../startup/clients.dart';
import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  /// Runs a Dio call and returns its status, an error status being a result too.
  static Future<String?> _dio(Future<Response<dynamic>> Function() call) async {
    try {
      return '${(await call()).statusCode}';
    } on DioException catch (e) {
      return 'DioException (${e.type.name})${e.response == null ? '' : ' ${e.response!.statusCode}'}';
    }
  }

  static Future<String?> _http(Future<http.BaseResponse> Function() call) async {
    try {
      return '${(await call()).statusCode}';
    } catch (e) {
      return '${e.runtimeType}';
    }
  }

  static Uri _u(String path) => Uri.parse('$jsonPlaceholder$path');

  static String _shorten(String text) => text.length > 80 ? '${text.substring(0, 80)}…' : text.replaceAll('\n', ' ');

  /// The events of a WebSocket are logged by hand.
  static Future<String?> _webSocketEcho() async {
    const url = 'wss://echo.websocket.events';
    void log(FloconWebSocketEventType type, {String? message, Object? error}) => floconLogWebSocketEvent(
        FloconWebSocketEvent(websocketUrl: url, event: type, message: message, error: error));
    final socket = await WebSocket.connect(url).timeout(const Duration(seconds: 8));
    log(FloconWebSocketEventType.open);
    final echo = Completer<String>();
    socket.listen(
      (m) {
        log(FloconWebSocketEventType.receiveMessage, message: '$m');
        if (!echo.isCompleted && '$m' == 'hello from Flocon') echo.complete('$m');
      },
      onError: (Object e) => log(FloconWebSocketEventType.error, error: e),
      onDone: () => log(FloconWebSocketEventType.closed),
    );
    socket.add('hello from Flocon');
    log(FloconWebSocketEventType.sendMessage, message: 'hello from Flocon');
    final reply = await echo.future.timeout(const Duration(seconds: 8), onTimeout: () => 'no echo');
    log(FloconWebSocketEventType.closing);
    await socket.close();
    return reply;
  }

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.network, children: [
        SampleSection(title: 'HTTP · Dio', children: [
          SampleActionRow(title: 'GET', detail: 'Simple JSON request', action: () => _dio(() => dio.get('/posts/1'))),
          SampleActionRow(title: 'GET with a query', detail: 'userId=1', action: () => _dio(() => dio.get('/posts', queryParameters: {'userId': 1}))),
          SampleActionRow(
            title: 'POST JSON',
            detail: 'Headers and JSON body',
            action: () => _dio(() => dio.post('/posts', data: {'title': 'foo', 'body': 'bar', 'userId': 1})),
          ),
          SampleActionRow(title: 'PUT', detail: 'Update a post', action: () => _dio(() => dio.put('/posts/1', data: {'id': 1, 'title': 'updated'}))),
          SampleActionRow(title: 'DELETE', detail: 'Delete a post', action: () => _dio(() => dio.delete('/posts/1'))),
          SampleActionRow(
            title: 'Image',
            detail: 'Body not sent to Flocon (isImage)',
            action: () => _dio(() => dio.get('https://picsum.photos/id/10/400/300', options: Options(responseType: ResponseType.bytes))),
          ),
          SampleActionRow(title: 'Slow call', detail: '3 seconds, to see the duration', action: () => _dio(() => dio.get('https://httpbin.org/delay/3'))),
          SampleActionRow(
            title: 'FormData upload',
            detail: 'Fields and a file',
            action: () => _dio(() => dio.post('https://httpbin.org/post',
                data: FormData.fromMap({'name': 'flocon', 'file': MultipartFile.fromString('hello', filename: 'hello.txt')}))),
          ),
        ]),
        SampleSection(title: 'HTTP · package:http', children: [
          SampleActionRow(title: 'GET', detail: 'Simple JSON request', action: () => _http(() => httpClient.get(_u('/todos/1')))),
          SampleActionRow(
            title: 'POST JSON',
            detail: 'Headers and JSON body',
            action: () => _http(() => httpClient.post(_u('/posts'), headers: {'content-type': 'application/json'}, body: '{"title":"from http","userId":1}')),
          ),
          SampleActionRow(title: 'PUT', detail: 'Form body', action: () => _http(() => httpClient.put(_u('/posts/1'), body: {'title': 'updated'}))),
          SampleActionRow(title: 'DELETE', detail: 'Delete a post', action: () => _http(() => httpClient.delete(_u('/posts/1')))),
          SampleActionRow(
            title: 'Multipart upload',
            detail: 'Fields and a file',
            action: () => _http(() async {
              final request = http.MultipartRequest('POST', Uri.parse('https://httpbin.org/post'))
                ..fields['name'] = 'flocon'
                ..files.add(http.MultipartFile.fromString('file', 'hello', filename: 'hello.txt'));
              return httpClient.send(request);
            }),
          ),
        ]),
        SampleSection(title: 'Errors', children: [
          SampleActionRow(title: '404 (Dio)', detail: 'HTTP error status', action: () => _dio(() => dio.get('/does-not-exist'))),
          SampleActionRow(title: '500 (Dio)', detail: 'Server error', action: () => _dio(() => dio.get('https://httpbin.org/status/500'))),
          SampleActionRow(title: 'Network error (Dio)', detail: 'Unknown host, logged with an error', action: () => _dio(() => dio.get('https://does-not-exist.invalid/'))),
          SampleActionRow(title: '404 (http)', detail: 'HTTP error status', action: () => _http(() => httpClient.get(_u('/does-not-exist')))),
          SampleActionRow(title: 'Network error (http)', detail: 'Unknown host, logged with an error', action: () => _http(() => httpClient.get(Uri.parse('https://does-not-exist.invalid/')))),
        ]),
        SampleSection(title: 'Realtime', children: [
          SampleActionRow(title: 'WebSocket echo', detail: 'Events logged by hand', buttonTitle: 'Send', action: _webSocketEcho),
        ]),
        SampleSection(title: 'Mocks and bad network', children: [
          SampleActionRow(
            title: 'GET /posts/1 (Dio)',
            detail: 'Mock it, or turn on a bad network, from the desktop',
            action: () async {
              try {
                final r = await dio.get<dynamic>('/posts/1');
                return '${r.statusCode} · ${_shorten('${r.data}')}';
              } on DioException catch (e) {
                return 'DioException (${e.type.name}) ${_shorten('${e.response?.data ?? e.message ?? ''}')}';
              }
            },
          ),
          SampleActionRow(
            title: 'GET /posts/1 (http)',
            detail: 'Same call with package:http',
            action: () async {
              try {
                final r = await httpClient.get(_u('/posts/1'));
                return '${r.statusCode} · ${_shorten(r.body)}';
              } catch (e) {
                return '${e.runtimeType}: ${_shorten('$e')}';
              }
            },
          ),
        ]),
        const SampleInfoCard(
          'In Flocon Desktop, open Network > Mocks and create a mock for GET https://jsonplaceholder.typicode.com/posts/1, or turn on a '
          'Bad network configuration, then run the two calls above. Mocks are saved on the device and apply at the next launch too.',
        ),
      ]);
}
