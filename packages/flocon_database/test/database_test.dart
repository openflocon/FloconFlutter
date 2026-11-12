import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flocon/flocon.dart';
import 'package:flocon_database/flocon_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Object body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as Object));
}

FloconMessageFromServer _msg(String method, Map<String, Object?> body) =>
    FloconMessageFromServer(plugin: 'database', method: method, body: jsonEncode(body));

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late FloconSqliteExecutor executor;

  Future<Map<String, dynamic>> run(String sql) async =>
      jsonDecode((await executor.execute(path, sql)).toJson()) as Map<String, dynamic>;
  Map<String, dynamic> body(Map<String, dynamic> result) => jsonDecode(result['body'] as String) as Map<String, dynamic>;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('flocon_db');
    path = '${dir.path}/app.sqlite';
    executor = FloconSqliteExecutor(databaseFactoryFfi);
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, score REAL, avatar BLOB)');
    await db.insert('users', {'name': 'Flo', 'score': 1.5, 'avatar': Uint8List.fromList([1, 2, 255])});
    await db.insert('users', {'name': null, 'score': 2.0, 'avatar': null});
    await db.close();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('executor', () {
    test('SELECT returns the columns and the values as text, null as null, blobs as hexadecimal', () async {
      final result = await run('SELECT id, name, score, avatar FROM users ORDER BY id');
      expect(result['type'], 'Select');
      expect(body(result), {
        'columns': ['id', 'name', 'score', 'avatar'],
        'values': [
          ['1', 'Flo', '1.5', "x'0102FF'"],
          ['2', null, '2.0', null],
        ],
      });
    });

    test('a blob above 64 bytes is truncated', () {
      final text = FloconSqliteExecutor.blobDescription(Uint8List(100));
      expect(text, startsWith("x'"));
      expect(text, endsWith("…' (100 bytes)"));
      expect(text.length, 2 + 128 + '…\' (100 bytes)'.length);
      expect(FloconSqliteExecutor.blobDescription(Uint8List(0)), "x''");
    });

    test('PRAGMA, EXPLAIN and WITH are read like a SELECT', () async {
      expect((await run('PRAGMA table_info(users)'))['type'], 'Select');
      expect((await run('EXPLAIN SELECT 1'))['type'], 'Select');
      final cte = await run('WITH t AS (SELECT 7 AS n) SELECT n FROM t');
      expect(body(cte)['values'], [['7']]);
    });

    test('INSERT returns the inserted id, UPDATE and DELETE the affected count', () async {
      expect(body(await run("INSERT INTO users (name) VALUES ('David')")), {'insertedId': 3});
      expect(body(await run("UPDATE users SET score = 9 WHERE id <= 2")), {'affectedCount': 2});
      expect(body(await run('DELETE FROM users WHERE id = 3')), {'affectedCount': 1});
      expect((await run('DELETE FROM users WHERE id = 3'))['type'], 'UpdateDelete');
    });

    test('other statements succeed raw', () async {
      expect(await run('CREATE TABLE t (a INT)'), {'type': 'RawSuccess', 'body': '{}'});
      expect((await run('SELECT * FROM t'))['type'], 'Select');
    });

    test('an error gives its message and the original query', () async {
      final result = await run('SELEC nope');
      expect(result['type'], 'Error');
      expect(body(result)['originalSql'], 'SELEC nope');
      expect(body(result)['message'], contains('syntax error'));
      final missing = await run('SELECT * FROM missing');
      expect(body(missing)['message'], contains('no such table'));
    });
  });

  group('discovery', () {
    test('finds the SQLite files whatever their extension, not the others', () async {
      File('${dir.path}/store.bin').writeAsBytesSync(File(path).readAsBytesSync());
      Directory('${dir.path}/sub/deeper').createSync(recursive: true);
      File('${dir.path}/sub/deeper/nested.db').writeAsBytesSync(File(path).readAsBytesSync());
      File('${dir.path}/notes.txt').writeAsStringSync('hello');
      File('${dir.path}/tiny').writeAsStringSync('SQL');
      final found = await FloconDatabaseDiscovery(() async => [dir, Directory('${dir.path}/missing')]).databases();
      expect(found.map((d) => d.displayName), ['app.sqlite', 'nested.db', 'store.bin']);
    });

    test('depth is limited', () async {
      Directory('${dir.path}/a/b/c/d').createSync(recursive: true);
      File('${dir.path}/a/b/c/d/deep.db').writeAsBytesSync(File(path).readAsBytesSync());
      final found = await FloconDatabaseDiscovery(() async => [dir], maxDepth: 2).databases();
      expect(found.map((d) => d.displayName), ['app.sqlite']);
    });
  });

  group('plugin', () {
    late _Sender sender;
    late FloconDatabasePlugin plugin;

    setUp(() {
      sender = _Sender();
      plugin = FloconDatabasePlugin(
        sender: sender,
        discovery: FloconDatabaseDiscovery(() async => [dir]),
        executor: executor,
        now: () => DateTime.fromMillisecondsSinceEpoch(42),
      );
    });

    test('lists the databases by id (path) and name, on request and on connection', () async {
      await plugin.handleMessage(_msg('get_databases', {}));
      final message = sender.sent.single;
      expect((message.plugin, message.method), ('database', 'get_databases'));
      expect(message.body, [
        {'id': FloconDatabaseFile.idOf(path), 'name': 'app.sqlite'},
      ]);
      plugin.onConnectedToServer();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(sender.sent, hasLength(2));
    });

    test('runs a query on a listed database and answers with the request id', () async {
      await plugin.handleMessage(_msg('query', {'requestId': 'r1', 'database': path, 'query': 'SELECT name FROM users WHERE id = 1'}));
      final message = sender.sent.single;
      expect(message.method, 'query');
      final answer = message.body as Map<String, dynamic>;
      expect(answer['requestId'], 'r1');
      final result = jsonDecode(answer['result'] as String) as Map<String, dynamic>;
      expect(result['type'], 'Select');
      expect(jsonDecode(result['body'] as String), {'columns': ['name'], 'values': [['Flo']]});
    });

    test('refuses a database that is not listed', () async {
      final other = File('${Directory.systemTemp.path}/not_listed_${DateTime.now().microsecondsSinceEpoch}.db')
        ..writeAsBytesSync(File(path).readAsBytesSync());
      addTearDown(other.deleteSync);
      await plugin.handleMessage(_msg('query', {'requestId': 'r2', 'database': other.path, 'query': 'SELECT 1'}));
      final result = jsonDecode((sender.sent.single.body as Map)['result'] as String) as Map<String, dynamic>;
      expect(result['type'], 'Error');
      expect(jsonDecode(result['body'] as String)['message'], contains('Unknown database'));
    });

    test('a registered database is listed, a registered file at a known path renames it', () async {
      final elsewhere = File('${Directory.systemTemp.path}/shared_${DateTime.now().microsecondsSinceEpoch}.db')
        ..writeAsBytesSync(File(path).readAsBytesSync());
      addTearDown(elsewhere.deleteSync);
      plugin.register(FloconDatabaseFile(displayName: 'Shared', path: elsewhere.path));
      plugin.register(FloconDatabaseFile(displayName: 'Main', path: path));
      plugin.register(FloconDatabaseFile(displayName: 'Gone', path: '${dir.path}/gone.db'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      sender.sent.clear();
      await plugin.handleMessage(_msg('get_databases', {}));
      final names = ((sender.sent.single.body as List).cast<Map>()).map((d) => d['name']);
      expect(names, ['Main', 'Shared']);
    });

    test('logs the queries of the app, linked to their database', () {
      plugin.logQuery(FloconDatabaseFile.idOf(path), 'SELECT * FROM users WHERE id = ?', [42, null, 'a']);
      final message = sender.sent.single;
      expect((message.plugin, message.method), ('database', 'log_query'));
      expect(message.body, {
        'dbId': FloconDatabaseFile.idOf(path),
        'sqlQuery': 'SELECT * FROM users WHERE id = ?',
        'bindArgs': ['42', 'null', 'a'],
        'timestamp': 42,
      });
    });

    test('unreadable requests are ignored', () async {
      await plugin.handleMessage(const FloconMessageFromServer(plugin: 'database', method: 'query', body: 'nope'));
      await plugin.handleMessage(_msg('query', {'wrong': true}));
      await plugin.handleMessage(_msg('unknown', {}));
      expect(sender.sent, isEmpty);
    });
  });

  test('the facades do nothing before initialize', () async {
    await floconEnableDatabasePlugin(searchDirectories: const []);
    Flocon.database.register('x', '/tmp/x.db');
    Flocon.database.logQuery('/tmp/x.db', 'SELECT 1');
    expect(Flocon.plugin<FloconDatabasePlugin>(), isNull);
  });
}
