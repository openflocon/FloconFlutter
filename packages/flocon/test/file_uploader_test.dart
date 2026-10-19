import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Directory dir;
  final received = Completer<({String contentType, String userAgent, String path, String body})>();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('flocon_upload');
    server = await HttpServer.bind('localhost', 0);
    server.listen((request) async {
      final body = utf8.decode(await request.fold<List<int>>([], (a, b) => a..addAll(b)));
      if (!received.isCompleted) {
        received.complete((
          contentType: request.headers.contentType.toString(),
          userAgent: request.headers.value('user-agent') ?? '',
          path: request.uri.path,
          body: body,
        ));
      }
      request.response.statusCode = 200;
      await request.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  test('uploads the file and the identity fields as multipart/form-data', () async {
    final file = File('${dir.path}/data.txt')..writeAsStringSync('hello flocon');
    await FloconFileUploader(host: 'localhost', port: server.port).upload(
      file,
      remotePath: '/app/data.txt',
      requestId: 'req-1',
      identity: const FloconUploadIdentity(deviceId: 'dev', appPackageName: 'pkg', appInstance: 42),
    );
    final r = await received.future;
    expect(r.path, '/upload');
    expect(r.userAgent, 'Flocon');
    expect(r.contentType, startsWith('multipart/form-data; boundary=Flocon-'));
    for (final part in [
      'name="remotePath"\r\n\r\n/app/data.txt',
      'name="requestId"\r\n\r\nreq-1',
      'name="deviceId"\r\n\r\ndev',
      'name="appPackageName"\r\n\r\npkg',
      'name="appInstance"\r\n\r\n42',
      'name="file"; filename="data.txt"',
      'hello flocon',
    ]) {
      expect(r.body, contains(part));
    }
    expect(r.body.trimRight(), endsWith('--'));
  });

  test('an unreachable desktop does not throw', () async {
    final file = File('${dir.path}/data.txt')..writeAsStringSync('x');
    final port = server.port;
    await server.close(force: true);
    await FloconFileUploader(host: 'localhost', port: port).upload(
      file,
      remotePath: 'p',
      requestId: 'r',
      identity: const FloconUploadIdentity(deviceId: 'd', appPackageName: 'p', appInstance: 1),
    );
  });
}
