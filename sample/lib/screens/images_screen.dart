import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../startup/clients.dart';
import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';
import '../widgets/sample_widgets.dart';

/// Downloads images through Dio and package:http and displays them. Image responses are flagged `isImage` in Flocon: the
/// desktop shows them as pictures instead of a body.
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  static const _urls = [
    'https://picsum.photos/id/10/400/300',
    'https://picsum.photos/id/20/400/300',
    'https://picsum.photos/id/30/400/300',
    'https://picsum.photos/id/40/400/300',
    'https://httpbin.org/image/png',
    'https://httpbin.org/image/jpeg',
  ];

  bool _useDio = true;
  Future<List<Uint8List>>? _images;

  Future<List<Uint8List>> _load() => Future.wait(_urls.map((url) async {
        if (_useDio) {
          final r = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
          return Uint8List.fromList(r.data!);
        }
        return (await httpClient.get(Uri.parse(url))).bodyBytes;
      }));

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.images, children: [
        SampleSection(title: 'Load', children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: true, label: Text('Dio')), ButtonSegment(value: false, label: Text('package:http'))],
                selected: {_useDio},
                onSelectionChanged: (s) => setState(() => _useDio = s.first),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: SampleButton('Load 6 images', onPressed: () => setState(() => _images = _load()))),
            ]),
          ),
        ]),
        FutureBuilder<List<Uint8List>>(
          future: _images,
          builder: (context, snapshot) {
            if (_images == null) return const SizedBox.shrink();
            if (snapshot.hasError) return Text('${snapshot.error}', style: const TextStyle(color: SampleTheme.error));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final bytes in snapshot.data!)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, fit: BoxFit.cover)),
              ],
            );
          },
        ),
      ]);
}
