import 'dart:async';

import 'client/address_store.dart';
import 'client/connection_state.dart';
import 'client/connections.dart';
import 'client/flocon_client.dart';
import 'config.dart';
import 'core/logger.dart';
import 'core/plugin.dart';
import 'core/storage.dart';
import 'plugins/analytics/analytics_plugin.dart';
import 'plugins/deeplinks/deeplinks_plugin.dart';
import 'plugins/feature_flags/feature_flags_plugin.dart';
import 'plugins/network/network_plugin.dart';
import 'plugins/network/network_store.dart';
import 'plugins/table/table_plugin.dart';
import 'plugins/timeline/timeline_plugin.dart';

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
  static FloconConnections? _connections;
  static final _states = FloconConnectionStateStore();

  static bool get isInitialized => _client != null;

  /// Prints what the SDK does (connection, errors) in the console, prefixed with `[Flocon]`. Off by default.
  static bool get isLoggingEnabled => FloconLogger.enabled;
  static set isLoggingEnabled(bool value) => FloconLogger.enabled = value;

  /// Whether a connection to a desktop app is currently open.
  static bool get isConnected => _client?.isConnected ?? false;

  /// The state of the connection: connected as soon as one address is.
  static FloconConnectionState get connectionState => _states.state;

  /// The states of the connection, starting with the current one.
  static Stream<FloconConnectionState> get connectionStates => _states.stream;

  /// The network plugin, or null before [initialize].
  static FloconNetworkPlugin? get networkPlugin =>
      _client?.plugin<FloconNetworkPlugin>();

  static FloconAnalyticsPlugin? get analyticsPlugin =>
      _client?.plugin<FloconAnalyticsPlugin>();

  static FloconTablePlugin? get tablePlugin =>
      _client?.plugin<FloconTablePlugin>();

  static FloconTimelinePlugin? get timelinePlugin =>
      _client?.plugin<FloconTimelinePlugin>();

  static FloconFeatureFlagsPlugin? get featureFlagsPlugin =>
      _client?.plugin<FloconFeatureFlagsPlugin>();

  static FloconDeeplinksPlugin? get deeplinksPlugin =>
      _client?.plugin<FloconDeeplinksPlugin>();

  /// Starts the SDK. It connects in the background to `config.host` (`localhost` by default), retrying every
  /// 3 seconds until a desktop is reachable, and again whenever the connection drops; what the app logs is kept in
  /// memory meanwhile. Calling it twice has no effect.
  static void initialize({FloconConfig config = const FloconConfig()}) {
    if (_client != null) return;
    final client = FloconClient(config);
    client.register(
      FloconNetworkPlugin(
        sender: client,
        store: FloconNetworkStore(() => floconStorageDirectory(client.config)),
      ),
    );
    client.register(FloconAnalyticsPlugin(sender: client));
    client.register(FloconTablePlugin(sender: client));
    client.register(FloconTimelinePlugin(sender: client));
    client.register(FloconFeatureFlagsPlugin(sender: client));
    client.register(FloconDeeplinksPlugin(sender: client));
    client.register(FloconTimelinePlugin(sender: client));
    client.register(FloconFeatureFlagsPlugin(sender: client));
    client.register(FloconDeeplinksPlugin(sender: client));
    _client = client;
    final connections = FloconConnections(
      client: client,
      states: _states,
      config: client.config,
      addressStore: FloconFileAddressStore(client.config),
    );
    _connections = connections;
    unawaited(connections.start());
  }

  /// Also connects the app to the desktop at [address], such as `192.168.1.20` or `192.168.1.20:10023:10024`
  /// (host, WebSocket port, HTTP port; an omitted port is the configured one), for example once the user has typed
  /// it or scanned the QR code of the desktop. The default address keeps being tried.
  ///
  /// What the app logged until now is sent, then the next messages right away. Returns its result instead of
  /// throwing. The address is tried again at the next launch (see [FloconConfig.rememberLastAddress]).
  static Future<FloconConnectResult> connect(String address) async =>
      await _connections?.connect(address) ??
      const FloconConnectResultNotStarted();

  /// Closes the connection made with [connect], and forgets its address. Does nothing if there is none.
  static Future<void> disconnect() async => _connections?.disconnect();

  /// Registers a custom plugin, replacing the one with the same name. No effect before [initialize].
  static void register(FloconPlugin plugin) => _client?.register(plugin);

  /// The registered plugin of type [T], or null.
  static T? plugin<T extends FloconPlugin>() => _client?.plugin<T>();

  /// Lets a plugin package send messages to the desktop app. Null before [initialize].
  static FloconMessageSender? get messageSender => _client;

  /// Lets a plugin package upload files to the desktop app. Null before [initialize].
  static FloconFileSender? get fileSender => _client;

  /// The configuration in use, or null before [initialize].
  static FloconConfig? get config => _client?.config;
}
