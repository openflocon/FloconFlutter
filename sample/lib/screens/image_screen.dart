import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../clients.dart';

/// Downloads images through Dio and package:http and displays them.
/// Image responses are flagged `isImage` in Flocon: the desktop shows them as pictures.
class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  static const _urls = [
    'https://picsum.photos/id/10/400/300',
    'https://picsum.photos/id/20/400/300',
    'https://picsum.photos/id/30/400/300',
    'https://picsum.photos/id/40/400/300',
    'https://httpbin.org/image/png',
    'https://httpbin.org/image/jpeg',
  ];

  bool _useDio = true;
  late Future<List<Uint8List>> _images = _load();

  Future<List<Uint8List>> _load() => Future.wait(_urls.map((url) async {
        if (_useDio) {
          final r = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
          return Uint8List.fromList(r.data!);
        }
        return (await httpClient.get(Uri.parse(url))).bodyBytes;
      }));

  void _reload({bool? useDio}) => setState(() {
        if (useDio != null) _useDio = useDio;
        _images = _load();
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Images'), actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ]),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Dio')),
                ButtonSegment(value: false, label: Text('package:http')),
              ],
              selected: {_useDio},
              onSelectionChanged: (s) => _reload(useDio: s.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Uint8List>>(
              future: _images,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(8),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final bytes in snapshot.data!)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                  ],
                );
              },
            ),
          ),
        ]),
      );
}
