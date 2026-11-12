import '../flocon.dart';
import 'network/web_socket_event.dart';

/// `Flocon.network`: the helpers of the Network plugin that are not interceptors.
class FloconNetworkApi {
  const FloconNetworkApi();

  /// Sends a WebSocket event to the desktop app. WebSocket traffic cannot be intercepted automatically: call this for
  /// each event of the connections you want to inspect.
  void logWebSocketEvent(FloconWebSocketEvent event) =>
      Flocon.networkPlugin?.logWebSocketEvent(event);
}

/// `Flocon.database`, the entry point of the Database plugin. Its methods (`register`, `logQuery`) are added by the
/// `flocon_database` package, which has to be imported.
class FloconDatabaseApi {
  const FloconDatabaseApi();
}

/// `Flocon.preferences`, the entry point of the Preferences plugin. Its methods (`register`) are added by the
/// `flocon_shared_preferences` package, which has to be imported.
class FloconPreferencesApi {
  const FloconPreferencesApi();
}

/// `Flocon.files`, the entry point of the Files plugin. Its methods (`register`) are added by the `flocon_files`
/// package, which has to be imported.
class FloconFilesApi {
  const FloconFilesApi();
}
