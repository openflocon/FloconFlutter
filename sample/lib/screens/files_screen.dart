import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'actions_view.dart';

/// Writes files in the app folders, to browse, download and delete from the Files section of Flocon.
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  static Future<String> _write(Directory dir, String name, String content) async {
    final folder = await dir.create(recursive: true);
    final file = File('${folder.path}/$name');
    await file.writeAsString(content);
    return file.path;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: ActionsView(actions: [
          SampleAction('Create a text file in documents', () async {
            final docs = await getApplicationDocumentsDirectory();
            return _write(docs, 'sample_${DateTime.now().millisecondsSinceEpoch}.txt', 'Hello from the Flocon sample\n${DateTime.now()}');
          }),
          SampleAction('Create a JSON file in documents/exports', () async {
            final docs = await getApplicationDocumentsDirectory();
            return _write(Directory('${docs.path}/exports'), 'export.json', '{"name": "flocon", "items": [1, 2, 3]}');
          }),
          SampleAction('Create a 2 MB file in the cache', () async {
            final cache = await getApplicationCacheDirectory();
            final file = File('${cache.path}/big.bin');
            await file.writeAsBytes(List<int>.filled(2 * 1024 * 1024, 7));
            return file.path;
          }),
          SampleAction('Show the app folders', () async {
            final docs = await getApplicationDocumentsDirectory();
            final cache = await getApplicationCacheDirectory();
            return 'documents: ${docs.path}\ncache: ${cache.path}';
          }),
        ]),
      );
}
