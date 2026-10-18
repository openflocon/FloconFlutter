import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../clients.dart';
import 'actions_view.dart';

class DioScreen extends StatelessWidget {
  const DioScreen({super.key});

  static Future<String> _call(Future<Response<dynamic>> Function() call) async {
    try {
      return '${(await call()).statusCode}';
    } on DioException catch (e) {
      return '${e.response?.statusCode ?? e.type.name}';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dio')),
        body: ActionsView(actions: [
          SampleAction('GET /posts/1', () => _call(() => dio.get('/posts/1'))),
          SampleAction('GET /posts?userId=1', () => _call(() => dio.get('/posts', queryParameters: {'userId': 1}))),
          SampleAction('POST /posts (JSON)', () => _call(() => dio.post('/posts', data: {'title': 'foo', 'body': 'bar', 'userId': 1}))),
          SampleAction('PUT /posts/1', () => _call(() => dio.put('/posts/1', data: {'id': 1, 'title': 'updated'}))),
          SampleAction('DELETE /posts/1', () => _call(() => dio.delete('/posts/1'))),
          SampleAction('404 not found', () => _call(() => dio.get('/does-not-exist'))),
          SampleAction('500 server error', () => _call(() => dio.get('https://httpbin.org/status/500'))),
          SampleAction('Network error', () => _call(() => dio.get('https://does-not-exist.invalid/'))),
          SampleAction('Slow request (3s)', () => _call(() => dio.get('https://httpbin.org/delay/3'))),
          SampleAction(
            'FormData upload',
            () => _call(() => dio.post('https://httpbin.org/post',
                data: FormData.fromMap({'name': 'flocon', 'file': MultipartFile.fromString('hello', filename: 'hello.txt')}))),
          ),
        ]),
      );
}
