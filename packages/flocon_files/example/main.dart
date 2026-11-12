import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // shows the usual folders of the app
    await startFlocon((flocon) => flocon..install(const FloconFiles()));
    Flocon.files.register('Exports', Directory('${Directory.systemTemp.path}/exports'));
  }
}
