import 'package:flocon/flocon.dart';
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();

  // Hooks FlutterError.onError and PlatformDispatcher.instance.onError; call it after Flocon.initialize().
  await floconEnableCrashReporter();
}
