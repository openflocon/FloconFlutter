import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'database_result.dart';

/// Runs the queries of the desktop on a SQLite file, on its own connection: the app may use the same file at the same
/// time.
class FloconSqliteExecutor {
  /// [factory] is `databaseFactory` of `sqflite` in an app; tests use the one of `sqflite_common_ffi`.
  FloconSqliteExecutor(this._factory);

  final DatabaseFactory _factory;

  static const maxBlobBytes = 64;

  Future<FloconDatabaseResult> execute(String path, String query) async {
    Database? db;
    try {
      db = await _factory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: false, singleInstance: false),
      );
      switch (_firstWord(query)) {
        case 'SELECT' || 'PRAGMA' || 'EXPLAIN' || 'WITH':
          final rows = await db.rawQuery(query);
          final columns = rows.isEmpty ? <String>[] : rows.first.keys.toList();
          return FloconSelectResult(columns, [
            for (final row in rows) [for (final c in columns) _text(row[c])],
          ]);
        case 'INSERT':
          return FloconInsertResult(await db.rawInsert(query));
        case 'UPDATE':
          return FloconUpdateDeleteResult(await db.rawUpdate(query));
        case 'DELETE':
          return FloconUpdateDeleteResult(await db.rawDelete(query));
        default:
          await db.execute(query);
          return const FloconRawSuccessResult();
      }
    } catch (e) {
      return FloconErrorResult(_message(e), query);
    } finally {
      try {
        await db?.close();
      } catch (_) {}
    }
  }

  static String _firstWord(String query) {
    final trimmed = query.trim();
    final end = trimmed.indexOf(RegExp(r'[\s(]'));
    return (end < 0 ? trimmed : trimmed.substring(0, end)).toUpperCase();
  }

  static String? _text(Object? value) => switch (value) {
        null => null,
        Uint8List() => blobDescription(value),
        _ => '$value',
      };

  /// A blob is shown as hexadecimal, truncated after [maxBlobBytes] bytes.
  static String blobDescription(Uint8List data) {
    if (data.isEmpty) return "x''";
    String hex(Iterable<int> bytes) =>
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
    return data.length > maxBlobBytes
        ? "x'${hex(data.take(maxBlobBytes))}…' (${data.length} bytes)"
        : "x'${hex(data)}'";
  }

  static String _message(Object error) {
    final text = '$error';
    // "DatabaseException(near "x": syntax error (code 1 SQLITE_ERROR): ...) sql '...' args []"
    final match = RegExp(r'DatabaseException\((.*?)\)(?: sql|\s*$)', dotAll: true).firstMatch(text);
    return match?.group(1) ?? text;
  }
}
