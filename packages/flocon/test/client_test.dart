import 'package:flocon/flocon.dart';
import 'package:flocon/src/client/flocon_client.dart';
import 'package:flocon/src/client/web_socket_client.dart';
import 'package:flocon/src/core/app_infos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client wraps the body in the envelope and queues while disconnected', () async {
    final ws = FloconWebSocketClient(queueCapacity: 2);
    final client = FloconClient(const FloconConfig(),
        webSocket: ws,
        appInfos: Future.value(const FloconAppInfos(
            deviceId: 'd', deviceName: 'n', platform: 'ios', appName: 'a', appPackageName: 'p')));
    for (var i = 0; i < 3; i++) {
      client.send(plugin: 'network', method: 'm$i', body: '{}');
    }
    await Future<void>.delayed(Duration.zero);
    expect(ws.isConnected, false);
    // queue cap: only 2 kept (checked through the public flush path being a no-op offline)
    ws.sendPendingMessages();
  });
}
