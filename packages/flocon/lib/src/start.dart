import 'config.dart';
import 'flocon.dart';

/// A plugin given to [FloconSetup.install], with its options.
///
/// Plugin packages extend it, for example `FloconFiles()` in `flocon_files`. [install] runs once Flocon is started.
abstract class FloconPluginFactory {
  const FloconPluginFactory();

  /// Registers the plugin. Called by [startFlocon], after `Flocon.initialize`.
  Future<void> install();
}

/// What [startFlocon] starts: the address of the desktop app and the plugins to install.
class FloconSetup {
  FloconSetup._();

  FloconConfig _config = const FloconConfig();
  final _factories = <FloconPluginFactory>[];

  /// The desktop app to connect to. `localhost` and the default ports when not called.
  ///
  /// [host] is the desktop host (`10.0.2.2` from the Android emulator, the IP of the computer from a physical device).
  /// Use the same ports as the desktop app if you changed them in its settings.
  void connect({
    String host = 'localhost',
    int webSocketPort = FloconConfig.defaultWebSocketPort,
    int httpPort = FloconConfig.defaultHttpPort,
    bool rememberLastAddress = true,
  }) {
    _config = FloconConfig(
      host: host,
      webSocketPort: webSocketPort,
      httpPort: httpPort,
      rememberLastAddress: rememberLastAddress,
    );
  }

  /// Installs a plugin, in the order of the calls. Installing the same type twice keeps the last one.
  void install(FloconPluginFactory factory) {
    _factories
      ..removeWhere((f) => f.runtimeType == factory.runtimeType)
      ..add(factory);
  }
}

/// Starts Flocon with the address of the desktop app and the plugins to install:
///
/// ```dart
/// if (kDebugMode) {
///   await startFlocon((flocon) => flocon
///     ..connect(host: '10.0.2.2')
///     ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'images.example.com'))
///     ..install(FloconFiles()));
/// }
/// ```
///
/// The plugins of the `flocon` package (network, analytics, tables, timeline, feature flags, deeplinks, dashboard)
/// are always available: install them only to give them options. The other packages each provide their own
/// factory (`FloconFiles`, `FloconDatabase`, `FloconCrashReporter`, `FloconSharedPreferences`).
///
/// Calling it again has no effect.
Future<void> startFlocon(void Function(FloconSetup flocon) setup) async {
  if (Flocon.isInitialized) return;
  final flocon = FloconSetup._();
  setup(flocon);
  Flocon.initialize(config: flocon._config);
  for (final factory in flocon._factories) {
    await factory.install();
  }
}
