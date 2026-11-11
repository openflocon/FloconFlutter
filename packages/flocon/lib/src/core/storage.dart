import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// The folder where the SDK keeps what must survive a restart.
Future<Directory> floconStorageDirectory(FloconConfig config) async {
  final base =
      config.storageDirectory ??
      Directory('${(await getApplicationSupportDirectory()).path}/flocon');
  return base.create(recursive: true);
}
