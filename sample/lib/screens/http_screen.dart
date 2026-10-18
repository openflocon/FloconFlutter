import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../clients.dart';
import 'actions_view.dart';

class HttpScreen extends StatelessWidget {
  const HttpScreen({super.key});

  static Future<String> _call(Future<http.BaseResponse> Function() call) async =>
      '${(await call()).statusCode}';

  static Uri _u(String path) => Uri.parse('$jsonPlaceholder$path');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('package:http')),
        body: ActionsView(actions: [
          SampleAction('GET /posts/1', () => _call(() => httpClient.get(_u('/posts/1')))),
          SampleAction('GET /posts?userId=1', () => _call(() => httpClient.get(_u('/posts?userId=1')))),
          SampleAction(
            'POST /posts (JSON)',
            () => _call(() => httpClient.post(_u('/posts'),
                headers: {'content-type': 'application/json'}, body: '{"title":"from http","userId":1}')),
          ),
          SampleAction('PUT /posts/1', () => _call(() => httpClient.put(_u('/posts/1'), body: {'title': 'updated'}))),
          SampleAction('DELETE /posts/1', () => _call(() => httpClient.delete(_u('/posts/1')))),
          SampleAction('404 not found', () => _call(() => httpClient.get(_u('/does-not-exist')))),
          SampleAction('500 server error', () => _call(() => httpClient.get(Uri.parse('https://httpbin.org/status/500')))),
          SampleAction('Network error', () => _call(() => httpClient.get(Uri.parse('https://does-not-exist.invalid/')))),
          SampleAction('Slow request (3s)', () => _call(() => httpClient.get(Uri.parse('https://httpbin.org/delay/3')))),
          SampleAction(
            'Multipart upload',
            () => _call(() async {
              final request = http.MultipartRequest('POST', Uri.parse('https://httpbin.org/post'))
                ..fields['name'] = 'flocon'
                ..files.add(http.MultipartFile.fromString('file', 'hello', filename: 'hello.txt'));
              return httpClient.send(request);
            }),
          ),
        ]),
      );
}
