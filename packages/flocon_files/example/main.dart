import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();

  // Shows the default folders of the app; call it after Flocon.initialize().
  await floconEnableFilesPlugin();
  floconRegisterFilesFolder('Exports', Directory('${Directory.systemTemp.path}/exports'));
}
