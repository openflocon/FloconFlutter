import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import '../config.dart';
import '../core/app_infos.dart';
import '../core/logger.dart';
import '../core/plugin.dart';
import '../model/message_from_server.dart';
import '../model/message_to_server.dart';
import 'file_uploader.dart';
import 'web_socket_client.dart';

/// Owns the WebSocket connection and the plugins; sends messages to the desktop and
/// routes incoming ones to the right plugin.
class FloconClient implements FloconMessageSender, FloconFileSender {
  FloconClient(this.config, {FloconWebSocketClient? webSocket, Future<FloconAppInfos>? appInfos})
      : _ws = webSocket ?? FloconWebSocketClient(),
        _appInfos = appInfos ?? FloconAppInfos.current();

  final FloconConfig config;
  final FloconWebSocketClient _ws;
  final Future<FloconAppInfos> _appInfos;
  final int _appInstance = DateTime.now().millisecondsSinceEpoch;
  final Map<String, FloconPlugin> _plugins = {};

  // Serial chain keeps messages ordered while the app infos are still loading.
  Future<void> _outbox = Future.value();

  bool get isConnected => _ws.isConnected;

  void register(FloconPlugin plugin) => _plugins[plugin.pluginName] = plugin;

  T? plugin<T extends FloconPlugin>() {
    for (final p in _plugins.values) {
      if (p is T) return p;
    }
    return null;
  }

  Future<void> connect({required void Function() onClosed}) async {
    await _ws.connect(
      address: config.host,
      port: config.webSocketPort,
      onMessageReceived: _onMessageReceived,
      onClosed: onClosed,
    );
    for (final p in _plugins.values) {
      p.onConnectedToServer();
    }
  }

  Future<void> disconnect() => _ws.disconnect();

  void sendPendingMessages() => _ws.sendPendingMessages();

  void _onMessageReceived(String text) {
    try {
      final message = FloconMessageFromServer.fromJson(jsonDecode(text) as Map<String, dynamic>);
      _plugins[message.plugin]?.onMessageReceived(message);
    } catch (_) {
      FloconLogger.log('Unreadable message from the desktop: $text');
    }
  }

  @override
  void send({required String plugin, required String method, required String body}) {
    _outbox = _outbox.then((_) async {
      try {
        final infos = await _appInfos;
        final json = jsonEncode(FloconMessageToServer(
          infos: infos,
          plugin: plugin,
          method: method,
          body: body,
          appInstance: _appInstance,
        ).toJson());
        _ws.send(json);
      } catch (e) {
        FloconLogger.logError('send failed', e);
      }
    });
  }

  @override
  Future<void> sendFile(File file, {required String remotePath, required String requestId}) async {
    try {
      final infos = await _appInfos;
      await FloconFileUploader(host: config.host, port: config.httpPort).upload(
        file,
        remotePath: remotePath,
        requestId: requestId,
        identity: FloconUploadIdentity(
          deviceId: infos.deviceId,
          appPackageName: infos.appPackageName,
          appInstance: _appInstance,
        ),
      );
    } catch (e) {
      FloconLogger.logError('sendFile failed', e);
    }
  }
}
