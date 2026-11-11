import 'core/io_types.dart';

import 'core/logger.dart';

/// Where the SDK finds the Flocon desktop app, and how it keeps what the app logs until it is reachable.
///
/// The defaults work from the iOS Simulator and desktop. From the Android emulator use
/// `10.0.2.2`; on a physical device use the local IP address of the computer running Flocon
/// (or [Flocon.connect], which also takes the ports, or the QR code of the desktop).
///
/// The ports must match the ones of the Flocon desktop settings (`9023` and `9024` by default).
class FloconConfig {
  const FloconConfig({
    this.host = 'localhost',
    this.webSocketPort = defaultWebSocketPort,
    this.httpPort = defaultHttpPort,
    this.bufferCapacity = 5000,
    this.additionalAddress,
    this.rememberLastAddress = true,
    this.storageDirectory,
  });

  static const defaultWebSocketPort = 9023;
  static const defaultHttpPort = 9024;

  /// Host name or IP address of the computer running the Flocon desktop app. Always tried.
  final String host;

  /// Port of the desktop WebSocket server (`wss://`).
  final int webSocketPort;

  /// Port of the desktop HTTP server (`https://`, used by the file downloads).
  final int httpPort;

  /// How many messages are kept while no desktop is reachable: above it, the oldest are dropped.
  final int bufferCapacity;

  /// Another address tried at start next to [host], such as `192.168.1.20` or `192.168.1.20:10023:10024`
  /// (the last address connected with [Flocon.connect] wins over it).
  final String? additionalAddress;

  /// Whether the last address connected with [Flocon.connect] is tried again at the next launch.
  final bool rememberLastAddress;

  /// Where the SDK keeps what must survive a restart (last address, network mocks).
  /// The application support folder by default.
  final Directory? storageDirectory;

  /// Version of the SDK, reported to the desktop app.
  static const sdkVersion = '0.2.0';

  /// The same configuration, with the ports outside 1...65535 and a non positive buffer replaced by the default ones.
  FloconConfig sanitized() {
    int port(int value, int fallback, String name) {
      if (value >= 1 && value <= 65535) return value;
      FloconLogger.log('Invalid $name $value, using $fallback');
      return fallback;
    }

    return FloconConfig(
      host: host,
      webSocketPort: port(
        webSocketPort,
        defaultWebSocketPort,
        'WebSocket port',
      ),
      httpPort: port(httpPort, defaultHttpPort, 'HTTP port'),
      bufferCapacity: bufferCapacity < 1 ? 5000 : bufferCapacity,
      additionalAddress: additionalAddress,
      rememberLastAddress: rememberLastAddress,
      storageDirectory: storageDirectory,
    );
  }
}
