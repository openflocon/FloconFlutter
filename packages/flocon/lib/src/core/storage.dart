import '../config.dart';
import 'io_types.dart';
import 'support_directory_io.dart'
    if (dart.library.js_interop) 'support_directory_web.dart';

/// The folder where the SDK keeps what must survive a restart.
Future<Directory> floconStorageDirectory(FloconConfig config) async {
  final base =
      config.storageDirectory ??
      Directory('${await applicationSupportPath()}/flocon');
  return base.create(recursive: true);
}
