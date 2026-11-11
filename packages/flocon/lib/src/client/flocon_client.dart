import 'dart:async';
import 'dart:convert';
import '../core/io_types.dart';

import '../config.dart';
import '../core/app_icon.dart';
import '../core/app_infos.dart';
import '../core/logger.dart';
import '../core/plugin.dart';
import '../model/message_from_server.dart';
import '../model/message_to_server.dart';
import 'address.dart';
import 'file_uploader.dart';
import 'outbox.dart';
import 'web_socket_client.dart';

/// One desktop the SDK connects to: the default address, or the one given to `Flocon.connect`.
class FloconLink {
  FloconLink(
    this.address, {
    required this.isDefault,
    FloconWebSocketClient? webSocket,
  }) : webSocket = webSocket ?? FloconWebSocketClient(),
       id = _nextId++ {
    outboxLink = FloconOutboxLink(this.webSocket.send);
  }

  static var _nextId = 0;

  final int id;
  final FloconAddress address;
  final bool isDefault;
  final FloconWebSocketClient webSocket;
  late final FloconOutboxLink outboxLink;

  /// Set to stop the attempts to connect to this address.
  var cancelled = false;

  bool get isConnected => webSocket.isConnected;
}

/// Owns the connections and the plugins; sends messages to the desktop and routes incoming ones to the right plugin.
class FloconClient implements FloconMessageSender, FloconFileSender {
  FloconClient(
    FloconConfig config, {
    Future<FloconAppInfos>? appInfos,
    Future<String?> Function()? appIcon,
  }) : config = config.sanitized(),
       _appInfos = appInfos ?? FloconAppInfos.current(),
       _appIcon = appIcon ?? FloconAppIcon.base64PNG {
    outbox = FloconOutbox(this.config.bufferCapacity);
    defaultLink = FloconLink(
      FloconAddress(
        host: this.config.host,
        webSocketPort: this.config.webSocketPort,
        httpPort: this.config.httpPort,
      ),
      isDefault: true,
    );
    outbox.add(defaultLink.outboxLink);
  }

  final FloconConfig config;
  final Future<FloconAppInfos> _appInfos;
  final Future<String?> Function() _appIcon;
  final int _appInstance = DateTime.now().millisecondsSinceEpoch;
  final Map<String, FloconPlugin> _plugins = {};
  late final FloconOutbox outbox;
  late final FloconLink defaultLink;

  /// The address added by `Flocon.connect`, next to the default one.
  FloconLink? extraLink;

  // The link the last message of the desktop came through: the file uploads go to the same desktop.
  FloconLink? _incomingLink;

  // Serial chain keeps messages ordered while the app infos are still loading.
  Future<void> _sending = Future.value();

  bool get isConnected =>
      defaultLink.isConnected || (extraLink?.isConnected ?? false);

  void register(FloconPlugin plugin) =>
      _plugins[plugin.pluginName.toLowerCase()] = plugin;

  T? plugin<T extends FloconPlugin>() {
    for (final p in _plugins.values) {
      if (p is T) return p;
    }
    return null;
  }

  FloconLink addExtraLink(FloconAddress address) {
    final link = FloconLink(address, isDefault: false);
    extraLink = link;
    outbox.add(link.outboxLink);
    return link;
  }

  Future<void> removeExtraLink(FloconLink link) async {
    link.cancelled = true;
    outbox.disconnected(link.outboxLink);
    outbox.remove(link.outboxLink);
    if (identical(extraLink, link)) extraLink = null;
    await link.webSocket.disconnect();
  }

  /// Opens the connection, introduces the app to the desktop, then lets the outbox send what was kept.
  /// Throws if the desktop is unreachable.
  Future<void> connect(
    FloconLink link, {
    required void Function() onClosed,
  }) async {
    await link.webSocket.connect(
      link.address.webSocketUri,
      onMessageReceived: (text) => _onMessageReceived(link, text),
      onClosed: () {
        outbox.disconnected(link.outboxLink);
        onClosed();
      },
    );
    final infos = await _appInfos;
    final handshake = _encode(
      infos,
      'bonjour',
      'bonjour',
      jsonEncode({'connectionType': link.isDefault ? 'default' : 'wifi'}),
    );
    outbox.connected(link.outboxLink, handshake);
    for (final p in _plugins.values) {
      p.onConnectedToServer();
    }
  }

  Future<void> disconnect(FloconLink link) => link.webSocket.disconnect();

  void _onMessageReceived(FloconLink link, String text) {
    try {
      final message = FloconMessageFromServer.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      _incomingLink = link;
      final plugin = message.plugin.toLowerCase();
      if (plugin == 'device') {
        if (message.method.toLowerCase() == 'get_app_icon') {
          unawaited(_sendAppIcon());
        }
        return;
      }
      _plugins[plugin]?.onMessageReceived(message);
    } catch (_) {
      FloconLogger.log('Unreadable message from the desktop: $text');
    }
  }

  Future<void> _sendAppIcon() async {
    final icon = await _appIcon();
    if (icon == null) {
      FloconLogger.log('App icon not found');
      return;
    }
    send(plugin: 'device', method: 'app_icon', body: icon);
  }

  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) {
    _sending = _sending.then((_) async {
      try {
        final infos = await _appInfos;
        outbox.enqueue(_encode(infos, plugin, method, body));
      } catch (e) {
        FloconLogger.logError('send failed', e);
      }
    });
  }

  String _encode(
    FloconAppInfos infos,
    String plugin,
    String method,
    String body,
  ) => jsonEncode(
    FloconMessageToServer(
      infos: infos,
      plugin: plugin,
      method: method,
      body: body,
      appInstance: _appInstance,
    ).toJson(),
  );

  @override
  Future<void> sendFile(
    File file, {
    required String remotePath,
    required String requestId,
  }) async {
    try {
      final infos = await _appInfos;
      final address = (_incomingLink ?? defaultLink).address;
      await FloconFileUploader(address.uploadUri).upload(
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
