import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../clients.dart';

/// Calls an endpoint and shows what the app received, to try the mocks and the bad network
/// simulation configured from the Flocon desktop app (Network > Mocks / Bad network).
class MocksScreen extends StatefulWidget {
  const MocksScreen({super.key});

  @override
  State<MocksScreen> createState() => _MocksScreenState();
}

class _MocksScreenState extends State<MocksScreen> {
  static const _url = '$jsonPlaceholder/posts/1';

  bool _useDio = true;
  String _result = 'Not called yet';
  bool _loading = false;

  Future<void> _call() async {
    setState(() {
      _loading = true;
      _result = 'Calling…';
    });
    final stopwatch = Stopwatch()..start();
    String result;
    try {
      if (_useDio) {
        final response = await dio.get<dynamic>('/posts/1');
        result = '${response.statusCode}\n${response.data}';
      } else {
        final response = await httpClient.get(Uri.parse(_url));
        result = '${response.statusCode}\n${response.body}';
      }
    } on DioException catch (e) {
      result = 'DioException (${e.type.name})\n${e.response?.statusCode ?? ''} ${e.response?.data ?? e.message ?? ''}';
    } catch (e) {
      result = '${e.runtimeType}\n$e';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = '$result\n\n${stopwatch.elapsedMilliseconds} ms';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mocks and bad network')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'In Flocon desktop, create a mock for GET $_url, or turn on a bad network '
              'configuration, then call it from here.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Dio')),
                ButtonSegment(value: false, label: Text('package:http')),
              ],
              selected: {_useDio},
              onSelectionChanged: (s) => setState(() => _useDio = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _call,
              icon: const Icon(Icons.play_arrow),
              label: const Text('GET /posts/1'),
            ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: SelectableText(_result))),
          ]),
        ),
      );
}
