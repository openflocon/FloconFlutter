import '../model/message_from_server.dart';

/// Sends a plugin message to the desktop app.
abstract interface class FloconMessageSender {
  /// [body] is the plugin payload, already encoded as a JSON string.
  void send({required String plugin, required String method, required String body});
}

/// A feature of the SDK (network, ...) that exchanges messages with the desktop app.
abstract interface class FloconPlugin {
  String get pluginName;
  void onConnectedToServer();
  void onMessageReceived(FloconMessageFromServer message);
}
