import 'package:flocon/flocon.dart';
import 'package:flocon_device/flocon_device.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, String body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: body));
}

FloconMessageFromServer _msg(String method) =>
    FloconMessageFromServer(plugin: 'device', method: method, body: '');

void main() {
  test('replies to getAppIcon with the base64 icon', () async {
    final sender = _Sender();
    final plugin = FloconDevicePlugin(sender: sender, iconLoader: () async => 'AAAA');
    await plugin.handleMessage(_msg('getAppIcon'));
    expect(sender.sent.single, (plugin: 'device', method: 'appIcon', body: 'AAAA'));
  });

  test('sends nothing when the icon is unavailable or the method is unknown', () async {
    final sender = _Sender();
    final plugin = FloconDevicePlugin(sender: sender, iconLoader: () async => null);
    await plugin.handleMessage(_msg('getAppIcon'));
    await plugin.handleMessage(_msg('restartApp'));
    expect(sender.sent, isEmpty);
  });

  test('enabling is a no-op before Flocon.initialize', () {
    floconEnableDevicePlugin();
  });
}
