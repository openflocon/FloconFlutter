/// Where the SDK finds the Flocon desktop app.
///
/// The defaults work from the iOS Simulator and desktop. From the Android emulator use
/// `10.0.2.2`; on a physical device use the local IP address of the computer running Flocon.
class FloconConfig {
  const FloconConfig({
    this.host = 'localhost',
    this.webSocketPort = 9023,
    this.httpPort = 9024,
  });

  /// Host name or IP address of the computer running the Flocon desktop app.
  final String host;

  /// Port of the desktop WebSocket server.
  final int webSocketPort;

  /// Port of the desktop HTTP server (files, unused for now).
  final int httpPort;

  /// Version of the SDK, reported to the desktop app.
  static const sdkVersion = '0.1.0';
}
