import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:path_provider/path_provider.dart';

import 'file_system.dart';
import 'files_plugin.dart';

/// Lets the Flocon desktop app browse, download and delete the files of the app.
///
/// By default the `files` root is the data folder of the app (the parent of the documents folder) on
/// Android and iOS, and the application support folder on desktop; the `caches` root is the cache
/// folder. Nothing outside of them is reachable. Pass [rootDirectory] and [cachesDirectory] to change them.
///
/// Call it after `Flocon.initialize()` (it does nothing before).
Future<void> floconEnableFilesPlugin({
  Directory? rootDirectory,
  Directory? cachesDirectory,
}) async {
  final sender = Flocon.messageSender;
  final fileSender = Flocon.fileSender;
  if (sender == null ||
      fileSender == null ||
      Flocon.plugin<FloconFilesPlugin>() != null) {
    return;
  }

  final root = rootDirectory ?? await _defaultRoot();
  final caches = cachesDirectory ?? await getApplicationCacheDirectory();
  Flocon.register(
    FloconFilesPlugin(
      sender: sender,
      fileSender: fileSender,
      fileSystem: FloconFileSystem(root: root, caches: caches),
    ),
  );
}

Future<Directory> _defaultRoot() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).parent;
  }
  // On desktop the documents folder is the one of the user: stay in the folder of the app.
  return getApplicationSupportDirectory();
}
