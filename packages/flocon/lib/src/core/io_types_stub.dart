/// Stand-in for `dart:io`'s `File` on platforms without a file system (the web). Every operation throws.
class File {
  File(this.path);

  final String path;

  Uri get uri => Uri.file(path);
  Directory get parent => throw _unsupported();
  Stream<List<int>> openRead() => throw _unsupported();
  Future<bool> exists() => throw _unsupported();
  Future<String> readAsString() => throw _unsupported();
  Future<File> writeAsString(String contents) => throw _unsupported();
  Future<File> delete() => throw _unsupported();
}

/// Stand-in for `dart:io`'s `Directory` on platforms without a file system (the web). Every operation throws.
class Directory {
  Directory(this.path);

  final String path;

  Future<Directory> create({bool recursive = false}) => throw _unsupported();
}

UnsupportedError _unsupported() =>
    UnsupportedError('The file system is not available on this platform.');
