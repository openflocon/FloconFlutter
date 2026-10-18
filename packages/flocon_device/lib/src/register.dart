import 'package:flocon/flocon.dart';

import 'device_plugin.dart';

/// Enables the device plugin, so that the app shows with its icon in the Flocon desktop app.
///
/// Call it after `Flocon.initialize()` (it does nothing before).
void floconEnableDevicePlugin() {
  final sender = Flocon.messageSender;
  if (sender == null) return;
  Flocon.register(FloconDevicePlugin(sender: sender));
}
