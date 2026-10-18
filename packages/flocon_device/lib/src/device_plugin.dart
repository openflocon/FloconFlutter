import 'dart:async';

import 'package:flocon/flocon.dart';

import 'app_icon.dart';

/// Answers the device requests of the Flocon desktop app.
///
/// When the desktop asks for the app icon (`getAppIcon`), replies with a base64 PNG (`appIcon`).
/// Restarting the app (`restartApp`) is not supported and is ignored.
class FloconDevicePlugin implements FloconPlugin {
  FloconDevicePlugin({required FloconMessageSender sender, Future<String?> Function()? iconLoader})
      : _sender = sender,
        _iconLoader = iconLoader ?? FloconAppIcon.base64PNG;

  static const name = 'device';
  static const methodGetAppIcon = 'getAppIcon'; // desktop -> app
  static const methodAppIcon = 'appIcon'; // app -> desktop

  final FloconMessageSender _sender;
  final Future<String?> Function() _iconLoader;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) => unawaited(handleMessage(message));

  Future<void> handleMessage(FloconMessageFromServer message) async {
    if (message.method != methodGetAppIcon) return;
    try {
      final icon = await _iconLoader();
      if (icon == null) return;
      _sender.send(plugin: pluginName, method: methodAppIcon, body: icon);
    } catch (_) {}
  }
}
