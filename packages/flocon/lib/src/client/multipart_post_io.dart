import 'dart:io';

/// Streams [head], the content of [file], then [tail] to [uri] over `https://`, accepting the self-signed
/// certificate of the desktop without verifying it. Returns the HTTP status code.
Future<int> postMultipart(
  Uri uri, {
  required String boundary,
  required List<int> head,
  required File file,
  required List<int> tail,
}) async {
  final client = HttpClient()..badCertificateCallback = (_, __, ___) => true;
  try {
    final request = await client
        .postUrl(uri)
        .timeout(const Duration(seconds: 10));
    request.headers
      ..set(HttpHeaders.userAgentHeader, 'Flocon')
      ..set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
    request.add(head);
    await request.addStream(file.openRead());
    request.add(tail);
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}
