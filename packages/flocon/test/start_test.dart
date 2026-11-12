import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Factory extends FloconPluginFactory {
  const _Factory(this.name, this.installed);
  final String name;
  final List<String> installed;

  @override
  Future<void> install() async {
    // plugins are installed once Flocon is started
    expect(Flocon.isInitialized, isTrue);
    installed.add(name);
  }
}

class _Other extends _Factory {
  const _Other(super.name, super.installed);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // real sockets: nothing listens on the port, so the connection keeps failing quietly
  HttpOverrides.global = null;

  setUpAll(() {
    // the platform plugins Flocon.initialize reads the app identity and its storage folder from
    PackageInfo.setMockInitialValues(
        appName: 'test', packageName: 'test', version: '1', buildNumber: '1', buildSignature: '');
    final storage = Directory.systemTemp.createTempSync('flocon_start');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage.path,
    );
  });

  test('startFlocon connects, installs the plugins in order and applies the network options', () async {
    final installed = <String>[];
    bool isImage(FloconHttpRequest request, FloconHttpResponse response) => request.url.host == 'img.test';

    await startFlocon((flocon) => flocon
      ..connect(host: '127.0.0.1', webSocketPort: 1, httpPort: 2, rememberLastAddress: false)
      ..install(_Factory('replaced', installed))
      ..install(FloconNetwork(isImage: isImage))
      ..install(_Other('other', installed))
      ..install(_Factory('first', installed)));

    expect(Flocon.config?.host, '127.0.0.1');
    expect(Flocon.config?.webSocketPort, 1);
    expect(Flocon.config?.httpPort, 2);
    // the same type installed twice keeps the last one
    expect(installed, ['other', 'first']);

    final network = Flocon.networkPlugin!;
    final image = FloconHttpRequest(url: Uri.parse('https://img.test/a'), method: 'GET');
    final other = FloconHttpRequest(url: Uri.parse('https://api.test/a'), method: 'GET');
    expect(network.isImage(image, const FloconHttpResponse()), isTrue);
    expect(network.isImage(other, const FloconHttpResponse()), isFalse);
    expect(network.isImage(other, const FloconHttpResponse(headers: {'content-type': 'image/png'})), isTrue);
    expect(network.shouldLog(other), isTrue);

    // a second call has no effect
    await startFlocon((flocon) => flocon.install(_Factory('again', installed)));
    expect(installed, ['other', 'first']);
  });
}
