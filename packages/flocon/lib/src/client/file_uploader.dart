import 'dart:convert';
import 'dart:math';

import '../core/io_types.dart';
import '../core/logger.dart';
import 'multipart_post_io.dart'
    if (dart.library.js_interop) 'multipart_post_web.dart';

/// Fields that identify the app, sent with every uploaded file.
class FloconUploadIdentity {
  const FloconUploadIdentity({
    required this.deviceId,
    required this.appPackageName,
    required this.appInstance,
  });

  final String deviceId;
  final String appPackageName;
  final int appInstance;
}

/// Uploads files to the HTTP server of the desktop app, as `multipart/form-data`, over `https://`
/// with its self-signed certificate (accepted without being verified).
/// The file is streamed, so that large files are never loaded in memory.
class FloconFileUploader {
  const FloconFileUploader(this.uploadUri);

  /// `https://host:httpPort/upload`
  final Uri uploadUri;

  Future<void> upload(
    File file, {
    required String remotePath,
    required String requestId,
    required FloconUploadIdentity identity,
  }) async {
    try {
      final boundary =
          'Flocon-${Random().nextInt(1 << 32)}-${DateTime.now().microsecondsSinceEpoch}';
      final status = await postMultipart(
        uploadUri,
        boundary: boundary,
        head: utf8.encode(
          multipartHead(
            boundary,
            fields: {
              'remotePath': remotePath,
              'requestId': requestId,
              'deviceId': identity.deviceId,
              'appPackageName': identity.appPackageName,
              'appInstance': '${identity.appInstance}',
            },
            fileName: file.uri.pathSegments.last,
          ),
        ),
        file: file,
        tail: utf8.encode(multipartTail(boundary)),
      );
      if (status < 200 || status >= 300) {
        FloconLogger.log('Upload of $remotePath failed: HTTP $status');
      }
    } catch (e) {
      FloconLogger.logError('Upload of $remotePath failed', e);
    }
  }

  /// The text fields, then the headers of the file part.
  static String multipartHead(
    String boundary, {
    required Map<String, String> fields,
    required String fileName,
  }) {
    final out = StringBuffer();
    for (final field in fields.entries) {
      out
        ..write('--$boundary\r\n')
        ..write('Content-Disposition: form-data; name="${field.key}"\r\n\r\n')
        ..write('${field.value}\r\n');
    }
    out
      ..write('--$boundary\r\n')
      ..write(
        'Content-Disposition: form-data; name="file"; filename="${fileName.replaceAll('"', '_')}"\r\n',
      )
      ..write('Content-Type: application/octet-stream\r\n\r\n');
    return out.toString();
  }

  static String multipartTail(String boundary) => '\r\n--$boundary--\r\n';
}
