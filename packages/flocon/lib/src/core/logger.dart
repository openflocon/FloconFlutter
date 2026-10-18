import 'package:flutter/foundation.dart';

/// Internal debug logging of the SDK. Silent in release builds.
class FloconLogger {
  static bool enabled = kDebugMode;

  static void log(String message) {
    if (enabled) debugPrint('[Flocon] $message');
  }

  static void logError(String message, Object error) => log('$message: $error');
}
