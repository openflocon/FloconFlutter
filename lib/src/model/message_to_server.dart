import '../config.dart';
import '../core/app_infos.dart';

/// Envelope of every message sent to the desktop app.
class FloconMessageToServer {
  const FloconMessageToServer({
    required this.infos,
    required this.plugin,
    required this.method,
    required this.body,
    required this.appInstance,
  });

  final FloconAppInfos infos;
  final String plugin;
  final String method;
  final String body;
  final int appInstance;

  Map<String, Object?> toJson() => {
        'deviceId': infos.deviceId,
        'plugin': plugin,
        'body': body,
        'appName': infos.appName,
        'appPackageName': infos.appPackageName,
        'method': method,
        'deviceName': infos.deviceName,
        'appInstance': appInstance,
        'platform': infos.platform,
        'versionName': FloconConfig.sdkVersion,
      };
}
