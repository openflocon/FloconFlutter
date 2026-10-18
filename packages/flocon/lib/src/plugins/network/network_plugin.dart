import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/plugin.dart';
import '../../model/message_from_server.dart';
import 'web_socket_event.dart';

/// Sends the network calls and WebSocket events of the app to the Flocon desktop app.
class FloconNetworkPlugin implements FloconPlugin {
  FloconNetworkPlugin({required FloconMessageSender sender}) : _sender = sender;

  static const name = 'network';
  static const methodLogRequest = 'logNetworkCallRequest';
  static const methodLogResponse = 'logNetworkCallResponse';
  static const methodLogWebSocketEvent = 'logWebSocketEvent';

  final FloconMessageSender _sender;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) {
    // TODO: network mocks and bad network simulation, configured from the desktop
  }

  /// Optional values are sent as explicit `null`s, as the desktop expects.
  void logRequest({
    required String callId,
    required String url,
    required String method,
    required int startTime,
    required Map<String, String> requestHeaders,
    String? requestBody,
    int? requestSize,
  }) =>
      _send(methodLogRequest, {
        'floconCallId': callId,
        'floconNetworkType': 'http',
        'url': url,
        'method': method,
        'startTime': startTime,
        'requestHeaders': requestHeaders,
        'requestBody': requestBody,
        'requestSize': requestSize,
        'isMocked': false,
      });

  void logResponse({
    required String callId,
    required double durationMs,
    int? httpCode,
    String? contentType,
    String? body,
    Map<String, String> headers = const {},
    int? size,
    String? error,
    Map<String, String>? requestHeaders,
    bool isImage = false,
  }) =>
      _send(methodLogResponse, {
        'floconCallId': callId,
        'floconNetworkType': 'http',
        'isMocked': false,
        'durationMs': durationMs,
        'isImage': isImage,
        'requestHeaders': requestHeaders,
        'responseHttpCode': httpCode,
        'responseContentType': contentType,
        'responseBody': body,
        'responseHeaders': headers,
        'responseSize': size,
        'responseGrpcStatus': null,
        'responseError': error,
      });

  void logWebSocketEvent(FloconWebSocketEvent event) => _send(methodLogWebSocketEvent, {
        'id': const Uuid().v4(),
        'event': switch (event.event) {
          FloconWebSocketEventType.closed => 'closed',
          FloconWebSocketEventType.closing => 'closing',
          FloconWebSocketEventType.error => 'error',
          FloconWebSocketEventType.receiveMessage => 'received',
          FloconWebSocketEventType.sendMessage => 'sent',
          FloconWebSocketEventType.open => 'open',
        },
        'url': event.websocketUrl,
        'size': event.size,
        'timestamp': event.timestamp.millisecondsSinceEpoch,
        'message': event.message,
        'error': event.error,
      });

  void _send(String method, Map<String, Object?> value) {
    try {
      _sender.send(plugin: pluginName, method: method, body: jsonEncode(value));
    } catch (_) {
      // logging must never break the app
    }
  }
}
