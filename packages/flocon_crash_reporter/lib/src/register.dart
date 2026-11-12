import 'dart:async';
import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'crash_reporter_plugin.dart';
import 'crash_store.dart';

/// The Crash reporter plugin, to install with `startFlocon`: reports the uncaught errors of the app to the Flocon
/// desktop app (see [floconEnableCrashReporter]).
///
/// ```dart
/// await startFlocon((flocon) => flocon..install(FloconCrashReporter()));
/// ```
class FloconCrashReporter extends FloconPluginFactory {
  const FloconCrashReporter({this.storeDirectory});

  /// Where the reports wait to be sent. A folder of the application support folder when null.
  final Directory? storeDirectory;

  @override
  Future<void> install() => floconEnableCrashReporter(storeDirectory: storeDirectory);
}

/// Reports the uncaught errors of the app to the Flocon desktop app. `install(FloconCrashReporter())` calls it.
///
/// It hooks `FlutterError.onError` (errors of the framework: build, layout, gestures...) and
/// `PlatformDispatcher.instance.onError` (uncaught asynchronous errors). The handlers that were
/// already set keep working: they are called after the report.
///
/// Call it after `Flocon.initialize()` (it does nothing before). The crashes of the previous launch
/// that were not sent are sent as soon as the desktop is connected.
///
/// Native crashes (Kotlin, Java, Swift, C++) are not reported.
Future<void> floconEnableCrashReporter({Directory? storeDirectory}) async {
  final sender = Flocon.messageSender;
  if (sender == null || Flocon.plugin<FloconCrashReporterPlugin>() != null) return;

  final directory = storeDirectory ??
      Directory('${(await getApplicationSupportDirectory()).path}/flocon_crashes');
  final plugin = FloconCrashReporterPlugin(sender: sender, store: FloconCrashStore(directory));
  Flocon.register(plugin);
  installFloconCrashHandlers(plugin);

  // crashes of a previous launch
  if (Flocon.isConnected) plugin.sendPendingCrashes();
}

/// Hooks the Flutter and platform error handlers, chaining the previous ones.
@visibleForTesting
void installFloconCrashHandlers(FloconCrashReporterPlugin plugin) {
  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    plugin.recordError(details.exception, details.stack);
    if (previousFlutterOnError != null) {
      previousFlutterOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    plugin.recordError(error, stack);
    // not handled by Flocon: let the previous handler decide, else the default behaviour (log) applies
    return previousPlatformOnError?.call(error, stack) ?? false;
  };
}
