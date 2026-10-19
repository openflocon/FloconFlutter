import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../core/logger.dart';

/// Fields that identify the app, sent with every uploaded file.
class FloconUploadIdentity {
  const FloconUploadIdentity({required this.deviceId, required this.appPackageName, required this.appInstance});

  final String deviceId;
  final String appPackageName;
  final int appInstance;
}

/// Uploads files to the HTTP server of the desktop app, as `multipart/form-data`.
/// The file is streamed, so that large files are never loaded in memory.
class FloconFileUploader {
  const FloconFileUploader({required this.host, required this.port});

  final String host;
  final int port;

  Future<void> upload(
    File file, {
    required String remotePath,
    required String requestId,
    required FloconUploadIdentity identity,
  }) async {
    final client = HttpClient();
    try {
      final boundary = 'Flocon-${Random().nextInt(1 << 32)}-${DateTime.now().microsecondsSinceEpoch}';
      final request = await client.postUrl(Uri.parse('http://$host:$port/upload')).timeout(const Duration(seconds: 10));
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'Flocon')
        ..set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');

      request.add(utf8.encode(multipartHead(
        boundary,
        fields: {
          'remotePath': remotePath,
          'requestId': requestId,
          'deviceId': identity.deviceId,
          'appPackageName': identity.appPackageName,
          'appInstance': '${identity.appInstance}',
        },
        fileName: file.uri.pathSegments.last,
      )));
      await request.addStream(file.openRead());
      request.add(utf8.encode(multipartTail(boundary)));

      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        FloconLogger.log('Upload of $remotePath failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      FloconLogger.logError('Upload of $remotePath failed', e);
    } finally {
      client.close(force: true);
    }
  }

  /// The text fields, then the headers of the file part.
  static String multipartHead(String boundary, {required Map<String, String> fields, required String fileName}) {
    final out = StringBuffer();
    for (final field in fields.entries) {
      out
        ..write('--$boundary\r\n')
        ..write('Content-Disposition: form-data; name="${field.key}"\r\n\r\n')
        ..write('${field.value}\r\n');
    }
    out
      ..write('--$boundary\r\n')
      ..write('Content-Disposition: form-data; name="file"; filename="${fileName.replaceAll('"', '_')}"\r\n')
      ..write('Content-Type: application/octet-stream\r\n\r\n');
    return out.toString();
  }

  static String multipartTail(String boundary) => '\r\n--$boundary--\r\n';
}
