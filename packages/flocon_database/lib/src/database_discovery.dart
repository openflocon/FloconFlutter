import 'dart:io';

import 'package:path/path.dart' as p;

/// A SQLite database the desktop can query.
class FloconDatabase {
  const FloconDatabase({required this.displayName, required this.path});

  final String displayName;
  final String path;

  /// The identifier sent to the desktop: the absolute path of the file.
  String get id => idOf(path);

  static String idOf(String path) => p.normalize(p.absolute(path));
}

/// Finds the SQLite files in the folders of the app, whatever their extension: a file is a SQLite database when it
/// starts with `SQLite format 3`.
class FloconDatabaseDiscovery {
  FloconDatabaseDiscovery(this._directories, {this.maxDepth = 3});

  final Future<List<Directory>> Function() _directories;
  final int maxDepth;

  static const _header = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00];

  Future<List<FloconDatabase>> databases() async {
    final found = <String, FloconDatabase>{};
    for (final directory in await _directories()) {
      await _scan(directory, 0, found);
    }
    return found.values.toList()..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  Future<void> _scan(Directory directory, int depth, Map<String, FloconDatabase> found) async {
    try {
      if (!await directory.exists()) return;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          if (await isSqlite(entity)) {
            final database = FloconDatabase(displayName: p.basename(entity.path), path: entity.path);
            found[database.id] = database;
          }
        } else if (entity is Directory && depth < maxDepth) {
          await _scan(entity, depth + 1, found);
        }
      }
    } catch (_) {
      // unreadable folder: skipped
    }
  }

  static Future<bool> isSqlite(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final bytes = await handle.read(_header.length);
      if (bytes.length < _header.length) return false;
      for (var i = 0; i < _header.length; i++) {
        if (bytes[i] != _header[i]) return false;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      await handle?.close();
    }
  }
}
