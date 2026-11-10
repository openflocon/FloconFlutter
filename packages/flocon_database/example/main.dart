import 'package:flocon/flocon.dart';
import 'package:flocon_database/flocon_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();

  // Lists the SQLite files of the usual folders; call it after Flocon.initialize().
  await floconEnableDatabasePlugin();
  floconRegisterDatabase('Shared', '/path/to/shared.sqlite');
}
