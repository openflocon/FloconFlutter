import 'package:path_provider/path_provider.dart';

/// The application support folder of the platform.
Future<String> applicationSupportPath() async =>
    (await getApplicationSupportDirectory()).path;
