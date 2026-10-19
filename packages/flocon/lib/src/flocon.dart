import 'dart:async';

import 'client/flocon_client.dart';
import 'config.dart';
import 'core/logger.dart';
import 'core/plugin.dart';
import 'plugins/analytics/analytics_plugin.dart';
import 'plugins/network/network_plugin.dart';
import 'plugins/table/table_plugin.dart';

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

  /// Whether the connection to the desktop app is currently open.
  static bool get isConnected => _client?.isConnected ?? false;

  /// The network plugin, or null before [initialize].
  static FloconNetworkPlugin? get networkPlugin => _client?.plugin<FloconNetworkPlugin>();

  static FloconAnalyticsPlugin? get analyticsPlugin => _client?.plugin<FloconAnalyticsPlugin>();

  static FloconTablePlugin? get tablePlugin => _client?.plugin<FloconTablePlugin>();

  /// Starts the SDK and connects to the desktop app, retrying every 3 seconds until reachable
  /// (and again whenever the connection drops). Calling it twice has no effect.
  static void initialize({FloconConfig config = const FloconConfig()}) {
    if (_client != null) return;
    final client = FloconClient(config);
    client.register(FloconNetworkPlugin(sender: client));
    client.register(FloconAnalyticsPlugin(sender: client));
    client.register(FloconTablePlugin(sender: client));
    _client = client;
    unawaited(_start(client));
  }

  /// Registers a custom plugin, replacing the one with the same name. No effect before [initialize].
  static void register(FloconPlugin plugin) => _client?.register(plugin);

  /// The registered plugin of type [T], or null.
  static T? plugin<T extends FloconPlugin>() => _client?.plugin<T>();

  /// Lets a plugin package send messages to the desktop app. Null before [initialize].
  static FloconMessageSender? get messageSender => _client;

  /// Lets a plugin package upload files to the desktop app. Null before [initialize].
  static FloconFileSender? get fileSender => _client;

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
