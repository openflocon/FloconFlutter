/// Registered by Flutter on Linux and Windows, which have no native code: the SDK runs entirely in Dart there,
/// and the app icon is simply not sent. Only declared so that those platforms are listed in the pubspec.
class FloconDartPlugin {
  FloconDartPlugin._();

  /// Called by the generated plugin registrant.
  static void registerWith() {}
}
