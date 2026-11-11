import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Registered by Flutter on the web, which has no native code: the SDK runs entirely in Dart there.
/// Only declared so that the web is listed in the pubspec.
class FloconWebPlugin {
  FloconWebPlugin._();

  /// Called by the generated plugin registrant.
  static void registerWith(Registrar registrar) {}
}
