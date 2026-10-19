import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flocon/flocon.dart';

import 'file_system.dart';

/// Lets the Flocon desktop app browse, download and delete the files of the app.
///
/// The desktop lists a folder (`listFiles`), downloads a file (`getFile`, sent over HTTP) and deletes
/// files or the content of a folder, after which the folder is listed again.
class FloconFilesPlugin implements FloconPlugin {
  FloconFilesPlugin({
    required FloconMessageSender sender,
    required FloconFileSender fileSender,
    required FloconFileSystem fileSystem,
  }) : _sender = sender,
       _fileSender = fileSender,
       _fileSystem = fileSystem;

  static const name = 'files';
  // desktop -> app
  static const methodListFiles = 'listFiles';
  static const methodGetFile = 'getFile';
  static const methodDeleteFile = 'deleteFile';
  static const methodDeleteFiles = 'deleteFiles';
  static const methodDeleteFolderContent = 'deleteFolderContent';
  // app -> desktop: older desktop versions compare method names case-sensitively
  static const methodListFilesResult = 'listFiles';

  final FloconMessageSender _sender;
  final FloconFileSender _fileSender;
  final FloconFileSystem _fileSystem;

  var _withFoldersSize = false;

  // File operations can be slow: they run in order.
  Future<void> _queue = Future.value();

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) =>
      unawaited(handleMessage(message));

  /// Resolves when the operation requested by [message] is done.
  Future<void> handleMessage(FloconMessageFromServer message) {
    final Map<String, dynamic> request;
    try {
      request = jsonDecode(message.body) as Map<String, dynamic>;
    } catch (_) {
      return Future.value();
    }
    switch (message.method) {
      case methodListFiles:
        _withFoldersSize = request['withFoldersSize'] as bool? ?? false;
        return _enqueue(
          () => _sendListing(
            request['path'] as String,
            request['isConstantPath'] as bool? ?? false,
            request['requestId'] as String,
          ),
        );
      case methodGetFile:
        // not queued: the upload of a big file must not block the listings
        return _sendFile(
          request['path'] as String,
          request['requestId'] as String,
        );
      case methodDeleteFile:
        return _enqueue(() async {
          await _fileSystem.deleteItem(request['filePath'] as String);
          await _sendListing(
            request['parentPath'] as String,
            request['isConstantParentPath'] as bool? ?? false,
            request['requestId'] as String,
          );
        });
      case methodDeleteFiles:
        return _enqueue(() async {
          for (final path
              in (request['filePaths'] as List<dynamic>).cast<String>()) {
            await _fileSystem.deleteItem(path);
          }
          await _sendListing(
            request['parentPath'] as String,
            request['isConstantParentPath'] as bool? ?? false,
            request['requestId'] as String,
          );
        });
      case methodDeleteFolderContent:
        return _enqueue(() async {
          final path = request['path'] as String;
          final isConstant = request['isConstantPath'] as bool? ?? false;
          final folder = _fileSystem.resolve(path, isConstantPath: isConstant);
          if (folder is Directory) await _fileSystem.deleteContents(folder);
          await _sendListing(path, isConstant, request['requestId'] as String);
        });
    }
    return Future.value();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _queue.then((_) async {
      try {
        await operation();
      } catch (_) {
        // a bad request must never break the app
      }
    });
    _queue = next;
    return next;
  }

  Future<void> _sendListing(
    String path,
    bool isConstantPath,
    String requestId,
  ) async {
    final folder = _fileSystem.resolve(path, isConstantPath: isConstantPath);
    final files = folder is Directory
        ? await _fileSystem.list(folder, withFoldersSize: _withFoldersSize)
        : const <FloconFileEntry>[];
    _sender.send(
      plugin: pluginName,
      method: methodListFilesResult,
      body: jsonEncode({
        'requestId': requestId,
        'files': [for (final f in files) f.toJson()],
      }),
    );
  }

  Future<void> _sendFile(String path, String requestId) async {
    try {
      final file = _fileSystem.resolve(path, isConstantPath: false);
      if (file is! File || !file.existsSync()) return;
      await _fileSender.sendFile(file, remotePath: path, requestId: requestId);
    } catch (_) {}
  }
}
