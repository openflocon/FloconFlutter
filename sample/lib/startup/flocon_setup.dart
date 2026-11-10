import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';
import 'package:flocon_database/flocon_database.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts Flocon and the plugins of the sample.
Future<void> initializeFlocon() async {
  Flocon.isLoggingEnabled = true;
  final prefs = await SharedPreferences.getInstance();
  await startFlocon((flocon) => flocon
    // Android emulator reaches the host machine through 10.0.2.2.
    // On a physical device, use Flocon.connect (or scan the QR code) with the local IP of the computer running Flocon.
    ..connect(host: Platform.isAndroid ? '10.0.2.2' : 'localhost')
    // images are shown by the desktop from their url: their body is not sent
    ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'picsum.photos'))
    ..install(const FloconFiles())
    ..install(const FloconDatabase())
    ..install(const FloconCrashReporter())
    ..install(FloconSharedPreferences(prefs)));
  FloconLifecycleObserver.start();
}
