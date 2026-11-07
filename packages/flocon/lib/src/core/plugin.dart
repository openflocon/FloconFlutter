import 'dart:io';

import '../model/message_from_server.dart';

/// Sends a plugin message to the desktop app.
abstract interface class FloconMessageSender {
  /// [body] is the plugin payload, already encoded as a JSON string.
  void send({
    required String plugin,
    required String method,
    required String body,
  });
}

/// Sends files to the Flocon desktop app, over its HTTP server.
abstract interface class FloconFileSender {
  /// [remotePath] is the path of the file as the desktop knows it, to match the upload with its
  /// request [requestId]. Never throws.
  Future<void> sendFile(
    File file, {
    required String remotePath,
    required String requestId,
  });
}

/// A feature of the SDK (network, ...) that exchanges messages with the desktop app.
abstract interface class FloconPlugin {
  String get pluginName;
  void onConnectedToServer();
  void onMessageReceived(FloconMessageFromServer message);
}
