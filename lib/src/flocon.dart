import 'dart:async';

import 'client/flocon_client.dart';
import 'config.dart';
import 'core/logger.dart';
import 'core/plugin.dart';
import 'plugins/network/network_plugin.dart';

/// Entry point of the Flocon SDK.
///
/// ```dart
/// void main() {
///   Flocon.initialize();
///   runApp(const MyApp());
/// }
/// ```
class Flocon {
  Flocon._();

  static FloconClient? _client;

  static bool get isInitialized => _client != null;

  /// The network plugin, or null before [initialize].
  static FloconNetworkPlugin? get networkPlugin => _client?.plugin<FloconNetworkPlugin>();

  /// Starts the SDK and connects to the desktop app, retrying every 3 seconds until reachable
  /// (and again whenever the connection drops). Calling it twice has no effect.
  static void initialize({FloconConfig config = const FloconConfig()}) {
    if (_client != null) return;
    final client = FloconClient(config);
    client.register(FloconNetworkPlugin(sender: client));
    _client = client;
    unawaited(_start(client));
  }

  /// Registers a custom plugin. No effect before [initialize].
  static void register(FloconPlugin plugin) => _client?.register(plugin);

  static Future<void> _start(FloconClient client) async {
    while (true) {
      try {
        await client.connect(onClosed: () => unawaited(_start(client)));
        client.send(plugin: 'bonjour', method: 'bonjour', body: 'bonjour');
        client.sendPendingMessages();
        return;
      } catch (e) {
        FloconLogger.logError('Cannot connect, retrying in 3s', e);
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }
}
