import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:path_provider/path_provider.dart';

import 'file_system.dart';
import 'files_plugin.dart';

/// Lets the Flocon desktop app browse, download and delete the files of the app.
///
/// Without anything to register, the desktop shows the documents, application support, cache and temporary folders
/// and, on Android and iOS, the whole data folder of the app. Register the other folders with
/// [floconRegisterFilesFolder]. Nothing outside of the root folders is reachable.
///
/// Call it after `Flocon.initialize()` (it does nothing before).
Future<void> floconEnableFilesPlugin({List<FloconFileRoot>? defaultRoots}) async {
  final sender = Flocon.messageSender;
  final fileSender = Flocon.fileSender;
  if (sender == null || fileSender == null || Flocon.plugin<FloconFilesPlugin>() != null) {
    return;
  }
  Flocon.register(FloconFilesPlugin(
    sender: sender,
    fileSender: fileSender,
    defaultRoots: defaultRoots ?? await _appDefaultRoots(),
  ));
}

/// Shows a folder in the Files section of the Flocon desktop app, under [displayName]; a folder already shown
/// is renamed. The plugin must be enabled with [floconEnableFilesPlugin] first (it does nothing before).
void floconRegisterFilesFolder(String displayName, Directory directory) {
  Flocon.plugin<FloconFilesPlugin>()?.register(
    FloconFileRoot.registered(displayName: displayName, directory: directory),
  );
}

Future<List<FloconFileRoot>> _appDefaultRoots() async {
  final documents = await getApplicationDocumentsDirectory();
  final support = await getApplicationSupportDirectory();
  final caches = await getApplicationCacheDirectory();
  final tmp = await getTemporaryDirectory();
  // Where the documents folder is the one of the app: Android, iOS, and the sandbox of macOS. On an unsandboxed
  // desktop it is the folder of the user, which is not shown.
  final isAppContainer =
      Platform.isAndroid || Platform.isIOS || Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID');
  return [
    if (isAppContainer) FloconFileRoot(id: 'documents', name: 'Documents', directory: documents),
    FloconFileRoot(id: 'applicationSupport', name: 'Application Support', directory: support),
    FloconFileRoot(id: 'caches', name: 'Caches', directory: caches),
    FloconFileRoot(id: 'tmp', name: 'tmp', directory: tmp),
    if (isAppContainer) FloconFileRoot(id: 'container', name: 'App container', directory: documents.parent),
  ];
}
