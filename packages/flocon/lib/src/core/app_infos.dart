import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
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
    var deviceName = Platform.operatingSystem;
    try {
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        deviceId = info.identifierForVendor ?? deviceId;
        deviceName = info.name;
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        deviceId = info.id;
        deviceName = '${info.manufacturer} ${info.model}';
      } else if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        deviceId = info.systemGUID ?? deviceId;
        deviceName = info.computerName;
      }
    } catch (_) {
      // keep the fallbacks
    }
    return FloconAppInfos(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : Platform.operatingSystem,
      appName: package.appName.isEmpty ? 'unknown' : package.appName,
      appPackageName: package.packageName.isEmpty ? 'unknown' : package.packageName,
    );
  }
}
