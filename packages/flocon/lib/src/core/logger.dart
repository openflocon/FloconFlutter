import 'package:flutter/foundation.dart';

/// Internal debug logging of the SDK. Silent in release builds.
class FloconLogger {
  /// Off by default: turn it on with `Flocon.isLoggingEnabled` to see what the SDK does.
  static bool enabled = false;

  static void log(String message) {
    if (enabled) debugPrint('[Flocon] $message');
  }

  static void logError(String message, Object error) => log('$message: $error');
}
