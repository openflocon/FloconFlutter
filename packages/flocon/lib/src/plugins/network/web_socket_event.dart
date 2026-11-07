import 'dart:convert';

import '../../flocon.dart';

enum FloconWebSocketEventType {
  closed,
  closing,
  error,
  receiveMessage,
  sendMessage,
  open,
}

/// An event of a WebSocket connection, shown with the network calls in the desktop app.
class FloconWebSocketEvent {
  FloconWebSocketEvent({
    required this.websocketUrl,
    required this.event,
    int? size,
    this.message,
    Object? error,
    DateTime? timestamp,
  }) : size = size ?? (message == null ? 0 : utf8.encode(message).length),
       error = error?.toString(),
       timestamp = timestamp ?? DateTime.now();

  final String websocketUrl;
  final FloconWebSocketEventType event;
  final int size;
  final String? message;
  final String? error;
  final DateTime timestamp;
}

/// Sends a WebSocket event to the desktop app. WebSocket traffic cannot be intercepted
/// automatically: call this for each event of the connections you want to inspect.
void floconLogWebSocketEvent(FloconWebSocketEvent event) =>
    Flocon.networkPlugin?.logWebSocketEvent(event);
