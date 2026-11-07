import 'dart:convert';
import 'dart:io';

import 'package:flocon_files/flocon_files.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

/// Writes files in the app folders, to browse, download and delete from the Files section of Flocon.
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  static Future<File> _write(Directory dir, String name, List<int> bytes) async {
    final folder = await dir.create(recursive: true);
    return File('${folder.path}/$name').writeAsBytes(bytes);
  }

  Future<String?> _writeSamples() async {
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final caches = await getApplicationCacheDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _write(docs, 'sample_$stamp.txt', utf8.encode('Hello from the Flocon sample\n${DateTime.now()}'));
    await _write(Directory('${docs.path}/exports'), 'export.json', utf8.encode('{"name": "flocon", "items": [1, 2, 3]}'));
    await _write(support, 'settings.json', utf8.encode('{"theme": "dark", "launches": 1}'));
    await _write(caches, 'cache.bin', List<int>.filled(256 * 1024, 7));
    return '4 files written';
  }

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.files, children: [
        SampleSection(title: 'Files', children: [
          SampleActionRow(
            title: 'Write sample files',
            detail: 'Text and JSON in Documents, Support and Caches',
            buttonTitle: 'Write',
            action: _writeSamples,
          ),
          SampleActionRow(
            title: 'Big file',
            detail: '5 MB in the caches, to see a streamed download',
            buttonTitle: 'Write',
            action: () async {
              final caches = await getApplicationCacheDirectory();
              final file = await _write(caches, 'big.bin', List<int>.filled(5 * 1024 * 1024, 7));
              return file.path;
            },
          ),
          SampleActionRow(
            title: 'Register a folder',
            detail: 'Shows documents/exports as "Exports" next to the default folders',
            buttonTitle: 'Register',
            action: () async {
              final docs = await getApplicationDocumentsDirectory();
              final exports = await Directory('${docs.path}/exports').create(recursive: true);
              floconRegisterFilesFolder('Exports', exports);
              return exports.path;
            },
          ),
        ]),
        const SampleInfoCard('Browse, download and delete them from Flocon > Files. A download is uploaded to the desktop over HTTPS, streamed.'),
      ]);
}
