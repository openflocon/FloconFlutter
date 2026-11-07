import 'dart:convert';
import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Map<String, dynamic> body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as Map<String, dynamic>));
}

class _FileSender implements FloconFileSender {
  final uploads = <({String path, String remotePath, String requestId})>[];
  @override
  Future<void> sendFile(File file, {required String remotePath, required String requestId}) async =>
      uploads.add((path: file.path, remotePath: remotePath, requestId: requestId));
}

FloconMessageFromServer _msg(String method, Map<String, Object?> body) =>
    FloconMessageFromServer(plugin: 'files', method: method, body: jsonEncode(body));

void main() {
  late Directory tmp, root, caches, outside;
  late _Sender sender;
  late _FileSender fileSender;
  late FloconFilesPlugin plugin;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('flocon_files');
    root = Directory('${tmp.path}/root')..createSync();
    caches = Directory('${tmp.path}/caches')..createSync();
    outside = Directory('${tmp.path}/outside')..createSync();
    File('${root.path}/b.txt').writeAsStringSync('hello');
    File('${root.path}/A.txt').writeAsStringSync('hi');
    Directory('${root.path}/docs').createSync();
    File('${root.path}/docs/inner.txt').writeAsStringSync('12345678');
    File('${caches.path}/cache.bin').writeAsStringSync('c');
    File('${outside.path}/secret.txt').writeAsStringSync('secret');
    sender = _Sender();
    fileSender = _FileSender();
    plugin = FloconFilesPlugin(
      sender: sender,
      fileSender: fileSender,
      fileSystem: FloconFileSystem(root: root, caches: caches),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  List<Map<String, dynamic>> files() => (sender.sent.last.body['files'] as List).cast<Map<String, dynamic>>();

  test('lists a constant root, sorted by name, with sizes and dates', () async {
    await plugin.handleMessage(_msg('list_files', {'requestId': 'r1', 'path': 'files', 'isConstantPath': true}));
    final message = sender.sent.single;
    expect((message.plugin, message.method, message.body['requestId']), ('files', 'list_files', 'r1'));
    expect(files().map((f) => f['name']), ['A.txt', 'b.txt', 'docs']);
    expect(files()[1], {
      'name': 'b.txt',
      'isDirectory': false,
      'path': '${root.path}/b.txt',
      'size': 5,
      'lastModified': isA<int>(),
    });
    expect(files()[2]['isDirectory'], true);
    expect(files()[2]['size'], 0);
  });

  test('computes the size of folders only when asked', () async {
    await plugin.handleMessage(
        _msg('list_files', {'requestId': 'r', 'path': 'files', 'isConstantPath': true, 'withFoldersSize': true}));
    expect(files().firstWhere((f) => f['name'] == 'docs')['size'], 8);
  });

  test('lists a folder by absolute path, and the caches root', () async {
    await plugin.handleMessage(_msg('list_files', {'requestId': 'r', 'path': '${root.path}/docs', 'isConstantPath': false}));
    expect(files().single['name'], 'inner.txt');
    await plugin.handleMessage(_msg('list_files', {'requestId': 'r', 'path': 'caches', 'isConstantPath': true}));
    expect(files().single['name'], 'cache.bin');
  });

  test('refuses folders outside the roots, including through .. and symbolic links', () async {
    Link('${root.path}/escape').createSync(outside.path);
    for (final path in [outside.path, '${root.path}/../outside', '${root.path}/escape', 'relative/path']) {
      sender.sent.clear();
      await plugin.handleMessage(_msg('list_files', {'requestId': 'r', 'path': path, 'isConstantPath': false}));
      expect(files(), isEmpty, reason: path);
    }
  });

  test('deletes a file then answers with the listing of its parent', () async {
    await plugin.handleMessage(_msg('delete_file', {
      'requestId': 'r',
      'parentPath': 'files',
      'isConstantParentPath': true,
      'filePath': '${root.path}/b.txt',
    }));
    expect(File('${root.path}/b.txt').existsSync(), false);
    expect(files().map((f) => f['name']), ['A.txt', 'docs']);
  });

  test('deletes a folder with its content and several files at once', () async {
    await plugin.handleMessage(_msg('delete_files', {
      'requestId': 'r',
      'parentPath': 'files',
      'isConstantParentPath': true,
      'filePaths': ['${root.path}/docs', '${root.path}/A.txt'],
    }));
    expect(files().map((f) => f['name']), ['b.txt']);
  });

  test('empties a folder, keeping it', () async {
    await plugin.handleMessage(_msg('delete_folder_content', {'requestId': 'r', 'path': 'files', 'isConstantPath': true}));
    expect(root.existsSync(), true);
    expect(files(), isEmpty);
  });

  test('never deletes outside the roots or the roots themselves', () async {
    for (final path in ['${outside.path}/secret.txt', root.path, caches.path, '${root.path}/../outside/secret.txt']) {
      await plugin.handleMessage(_msg('delete_file', {
        'requestId': 'r',
        'parentPath': 'files',
        'isConstantParentPath': true,
        'filePath': path,
      }));
    }
    expect(File('${outside.path}/secret.txt').existsSync(), true);
    expect(root.existsSync(), true);
    expect(caches.existsSync(), true);
  });

  test('deleting a symbolic link removes the link, not its target', () async {
    Link('${root.path}/link').createSync(outside.path);
    await plugin.handleMessage(_msg('delete_file', {
      'requestId': 'r',
      'parentPath': 'files',
      'isConstantParentPath': true,
      'filePath': '${root.path}/link',
    }));
    expect(FileSystemEntity.typeSync('${root.path}/link', followLinks: false), FileSystemEntityType.notFound);
    expect(File('${outside.path}/secret.txt').existsSync(), true);
  });

  test('getFile uploads a file of the roots, and ignores the others', () async {
    await plugin.handleMessage(_msg('get_file', {'requestId': 'r7', 'path': '${root.path}/b.txt'}));
    expect(fileSender.uploads.single, (path: '${root.path}/b.txt', remotePath: '${root.path}/b.txt', requestId: 'r7'));
    await plugin.handleMessage(_msg('get_file', {'requestId': 'r8', 'path': '${outside.path}/secret.txt'}));
    await plugin.handleMessage(_msg('get_file', {'requestId': 'r9', 'path': '${root.path}/missing.txt'}));
    expect(fileSender.uploads, hasLength(1));
  });

  test('unreadable requests are ignored', () async {
    await plugin.handleMessage(const FloconMessageFromServer(plugin: 'files', method: 'list_files', body: 'nope'));
    await plugin.handleMessage(_msg('list_files', {'wrong': true}));
    await plugin.handleMessage(_msg('unknown', {}));
    expect(sender.sent, isEmpty);
  });

  test('enabling is a no-op before Flocon.initialize', () async {
    await floconEnableFilesPlugin(rootDirectory: root, cachesDirectory: caches);
    expect(Flocon.plugin<FloconFilesPlugin>(), isNull);
  });
}
