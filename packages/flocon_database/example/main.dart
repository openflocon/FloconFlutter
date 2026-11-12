import 'package:flocon/flocon.dart';
import 'package:flocon_database/flocon_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // lists the SQLite files of the usual folders
    await startFlocon((flocon) => flocon..install(const FloconDatabase()));
    Flocon.database.register('Shared', '/path/to/shared.sqlite');
  }
}
