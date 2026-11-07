import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:path/path.dart' as p;

/// A file or folder of a listing, in the JSON format the desktop expects.
class FloconFileEntry {
  const FloconFileEntry({
    required this.name,
    required this.isDirectory,
    required this.path,
    required this.size,
    required this.lastModified,
  });

  final String name;
  final bool isDirectory;

  /// Absolute path, sent back by the desktop to open, download or delete the item.
  final String path;

  /// In bytes. For a folder, the size of its content when requested, 0 otherwise.
  final int size;

  /// In milliseconds since 1970.
  final int lastModified;

  Map<String, Object> toJson() => {
    'name': name,
    'isDirectory': isDirectory,
    'path': path,
    'size': size,
    'lastModified': lastModified,
  };
}

/// A folder the desktop can open, shown at the top of the Files section.
class FloconFileRoot {
  const FloconFileRoot({
    required this.id,
    required this.name,
    required this.directory,
  });

  /// A folder registered by the app, identified by its resolved path.
  FloconFileRoot.registered({required String displayName, required this.directory})
      : id = FloconFileSystem.resolvePath(directory.path),
        name = displayName;

  /// Stable identifier, sent back by the desktop as a constant path.
  final String id;

  /// Name shown in the desktop app.
  final String name;
  final Directory directory;
}

/// File operations requested by the desktop, limited to the root folders.
///
/// The desktop opens a root folder by its [FloconFileRoot.id], then any path inside it. Any path outside of
/// every root is refused, symbolic links being resolved. The root folders themselves are never deleted.
class FloconFileSystem {
  FloconFileSystem({required this.roots});

  /// The folders the desktop can access, in the order they are shown.
  final List<FloconFileRoot> roots;

  /// The roots that exist, as shown in the desktop app.
  List<FloconFileRoot> get existingRoots => [
        for (final root in roots)
          if (root.directory.existsSync()) root,
      ];

  /// The folder or file a desktop path points to, or null if it is outside the roots.
  FileSystemEntity? resolve(String path, {required bool isConstantPath}) {
    if (isConstantPath) {
      for (final root in roots) {
        if (root.id == path) return root.directory;
      }
      return null;
    }
    if (!p.isAbsolute(path) || !contains(path)) return null;
    return FileSystemEntity.isDirectorySync(path) ? Directory(path) : File(path);
  }

  /// Whether a path is a root folder or inside one, once `..` and symbolic links are resolved.
  bool contains(String path) => _within(resolvePath(path));

  bool _within(String resolvedPath) {
    final candidate = p.split(resolvedPath);
    return roots.any((root) {
      final base = p.split(resolvePath(root.directory.path));
      return candidate.length >= base.length &&
          [for (var i = 0; i < base.length; i++) candidate[i] == base[i]].every((e) => e);
    });
  }

  /// Like [resolvePath], but a final symbolic link is kept as it is: it is the item itself, whatever it targets.
  static String _resolvedKeepingLink(String path) {
    final normalized = p.normalize(p.absolute(path));
    return p.join(resolvePath(p.dirname(normalized)), p.basename(normalized));
  }

  bool _isRoot(String resolved) => roots.any((root) => resolved == resolvePath(root.directory.path));

  /// Normalizes a path and resolves its symbolic links, also when it does not exist (the deepest
  /// existing parent is resolved).
  static String resolvePath(String path) {
    final normalized = p.normalize(p.absolute(path));
    try {
      return FileSystemEntity.typeSync(normalized, followLinks: false) == FileSystemEntityType.notFound
          ? p.join(resolvePath(p.dirname(normalized)), p.basename(normalized))
          : File(normalized).resolveSymbolicLinksSync();
    } catch (_) {
      return normalized;
    }
  }

  // MARK: Listing

  /// The content of a folder, sorted by name. Empty if it cannot be read.
  Future<List<FloconFileEntry>> list(
    Directory folder, {
    required bool withFoldersSize,
  }) async {
    final entries = <FloconFileEntry>[];
    try {
      await for (final child in folder.list(followLinks: false)) {
        try {
          final stat = await child.stat();
          final isDirectory = stat.type == FileSystemEntityType.directory;
          entries.add(
            FloconFileEntry(
              name: p.basename(child.path),
              isDirectory: isDirectory,
              path: child.path,
              size: isDirectory
                  ? (withFoldersSize ? await _sizeOf(Directory(child.path)) : 0)
                  : stat.size,
              lastModified: stat.modified.millisecondsSinceEpoch,
            ),
          );
        } catch (_) {}
      }
    } catch (e) {
      FloconLogger.logError('Cannot list folder ${folder.path}', e);
    }
    return entries
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Future<int> _sizeOf(Directory folder) async {
    var total = 0;
    try {
      await for (final entity in folder.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  // MARK: Deleting

  /// Deletes a file or folder inside the roots. A symbolic link is removed, not followed.
  Future<void> deleteItem(String path) async {
    // a symbolic link is judged by where it lives, not by what it points to
    final resolved = p.isAbsolute(path) ? _resolvedKeepingLink(path) : null;
    if (resolved == null || !_within(resolved) || _isRoot(resolved)) {
      FloconLogger.log(
        'Refused to delete $path: outside the app folders or a root folder',
      );
      return;
    }
    try {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.directory:
          await Directory(path).delete(recursive: true);
        case FileSystemEntityType.link:
          await Link(path).delete();
        case FileSystemEntityType.file:
          await File(path).delete();
        default:
          break;
      }
    } catch (e) {
      FloconLogger.logError('Cannot delete $path', e);
    }
  }

  /// Deletes everything inside a folder, keeping the folder.
  Future<void> deleteContents(Directory folder) async {
    try {
      await for (final child in folder.list(followLinks: false)) {
        await deleteItem(child.path);
      }
    } catch (_) {}
  }
}
