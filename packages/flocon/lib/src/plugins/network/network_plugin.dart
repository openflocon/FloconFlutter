import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/plugin.dart';
import '../../model/message_from_server.dart';
import 'network_options.dart';
import 'network_overrides.dart';
import 'network_store.dart';
import 'web_socket_event.dart';

/// Sends the network calls and WebSocket events of the app to the Flocon desktop app.
class FloconNetworkPlugin implements FloconPlugin {
  FloconNetworkPlugin({
    required FloconMessageSender sender,
    Random? random,
    Future<void> Function(Duration)? delay,
    FloconNetworkStore? store,
  }) : _sender = sender,
       _random = random ?? Random(),
       _delay = delay ?? Future<void>.delayed,
        _store = store {
    ready = _loadSaved();
  }

  static const name = 'network';
  static const methodLogRequest = 'log_network_call_request';
  static const methodLogResponse = 'log_network_call_response';
  static const methodLogWebSocketEvent = 'log_websocket_event';
  static const methodSetupMocks = 'setup_mocks';
  static const methodSetupBadNetworkConfig = 'setup_bad_network_config';

  final FloconMessageSender _sender;
  final Random _random;
  final FloconNetworkStore? _store;
  final Future<void> Function(Duration) _delay;

  /// Completes once the mocks and the bad network configuration saved by the previous launch are loaded.
  /// The HTTP adapters wait for it before the first call.
  late final Future<void> ready;

  Future<void> _loadSaved() async {
    final store = _store;
    if (store == null) return;
    // never overwrite what the desktop already sent while loading
    final mocks = await store.loadMocks();
    if (mocks != null && this.mocks.isEmpty) this.mocks = parseMocks(mocks);
    final bad = await store.loadBadNetworkConfig();
    if (bad != null) badQualityConfig ??= parseBadQualityConfig(bad);
  }

  /// The options installed with `startFlocon` (`install(FloconNetwork(...))`).
  FloconNetwork options = const FloconNetwork();

  /// Whether [request] is sent to the desktop app, as decided by [FloconNetwork.shouldLog].
  bool shouldLog(FloconHttpRequest request) => options.shouldLog?.call(request) ?? true;

  /// Whether [response] is an image: a `Content-Type: image/*` header, or [FloconNetwork.isImage].
  bool isImage(FloconHttpRequest request, FloconHttpResponse response) =>
      (response.contentType?.toLowerCase().startsWith('image/') ?? false) ||
      (options.isImage?.call(request, response) ?? false);

  /// The mocks configured from the desktop. The first one matching a call wins.
  List<FloconMock> mocks = const [];

  /// The bad network simulation configured from the desktop, if any.
  FloconBadQualityConfig? badQualityConfig;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) {
    switch (message.method) {
      case methodSetupMocks:
        mocks = parseMocks(message.body);
        _store?.saveMocks(message.body);
      case methodSetupBadNetworkConfig:
        badQualityConfig = parseBadQualityConfig(message.body);
        _store?.saveBadNetworkConfig(
          badQualityConfig == null ? null : message.body,
        );
    }
  }

  /// The mock that answers this call, if any. Call it before [logRequest] to set `isMocked`.
  FloconMock? findMock(String url, String method) {
    for (final mock in mocks) {
      if (mock.matches(url, method)) return mock;
    }
    return null;
  }

  /// Applies the mock or the bad network simulation: waits for the configured delay, then returns what
  /// the HTTP adapter must answer instead of the real call, or null to perform the real call.
  Future<FloconNetworkOverride?> applyOverride(FloconMock? mock) async {
    if (mock != null) {
      if (mock.delay > Duration.zero) await _delay(mock.delay);
      return mock.toOverride();
    }
    final config = badQualityConfig;
    if (config == null) return null;
    if (config.shouldSimulateLatency(_random)) {
      await _delay(config.randomLatency(_random));
    }
    if (config.shouldFail(_random)) {
      return config.selectRandomError(_random)?.toOverride();
    }
    return null;
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
    bool isMocked = false,
  }) => _send(methodLogRequest, {
    'floconCallId': callId,
    'floconNetworkType': 'http',
    'url': url,
    'method': method,
    'startTime': startTime,
    'requestHeaders': requestHeaders,
    'requestBody': requestBody,
    'requestSize': requestSize,
    'isMocked': isMocked,
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
    bool isMocked = false,
  }) => _send(methodLogResponse, {
    'floconCallId': callId,
    'floconNetworkType': 'http',
    'isMocked': isMocked,
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

  void logWebSocketEvent(FloconWebSocketEvent event) =>
      _send(methodLogWebSocketEvent, {
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
