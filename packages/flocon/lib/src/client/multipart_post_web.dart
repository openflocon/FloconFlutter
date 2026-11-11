import '../core/io_types.dart';

/// Files cannot be read from disk on the web, so there is nothing to upload.
Future<int> postMultipart(
  Uri uri, {
  required String boundary,
  required List<int> head,
  required File file,
  required List<int> tail,
}) => throw UnsupportedError('Uploading files is not supported on the web.');
