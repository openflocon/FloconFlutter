import 'package:flutter/services.dart';

/// Reads the app icon through the native side.
class FloconAppIcon {
  static const _channel = MethodChannel('io.github.openflocon/flocon_device');

  /// The app icon as a base64 PNG, at most 300 pixels wide, or null if it cannot be read.
  static Future<String?> base64PNG() async {
    try {
      return await _channel.invokeMethod<String>('getAppIcon');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
