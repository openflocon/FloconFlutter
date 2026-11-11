import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Identity of the app and device, sent with every message.
class FloconAppInfos {
  const FloconAppInfos({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appName,
    required this.appPackageName,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String appName;
  final String appPackageName;

  static Future<FloconAppInfos> current() async {
    final package = await PackageInfo.fromPlatform();
    final plugin = DeviceInfoPlugin();
    var deviceId = const Uuid().v4();
    var deviceName = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        deviceName = info.browserName.name;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
            final info = await plugin.iosInfo;
            deviceId = info.identifierForVendor ?? deviceId;
            deviceName = info.name;
          case TargetPlatform.android:
            final info = await plugin.androidInfo;
            deviceId = info.id;
            deviceName = '${info.manufacturer} ${info.model}';
          case TargetPlatform.macOS:
            final info = await plugin.macOsInfo;
            deviceId = info.systemGUID ?? deviceId;
            deviceName = info.computerName;
          case TargetPlatform.windows:
            final info = await plugin.windowsInfo;
            deviceId = info.deviceId;
            deviceName = info.computerName;
          case TargetPlatform.linux:
            final info = await plugin.linuxInfo;
            deviceId = info.machineId ?? deviceId;
            deviceName = info.prettyName;
          case TargetPlatform.fuchsia:
            break;
        }
      }
    } catch (_) {
      // keep the fallbacks
    }
    return FloconAppInfos(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
      appName: package.appName.isEmpty ? 'unknown' : package.appName,
      appPackageName: package.packageName.isEmpty
          ? 'unknown'
          : package.packageName,
    );
  }
}
