import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:flocon/flocon.dart';

/// `package:http` client wrapper that sends every call to the Flocon desktop app.
///
/// ```dart
/// final client = FloconHttpClient(http.Client());
/// final response = await client.get(Uri.parse('https://example.com'));
/// ```
class FloconHttpClient extends http.BaseClient {
  FloconHttpClient(
    this._inner, {
    this.shouldLog,
    this.isImage,
    FloconNetworkPlugin? plugin,
  }) : _plugin = plugin;

  final http.Client _inner;
  final FloconNetworkPlugin? _plugin;

  /// Returns whether a request is sent to the desktop app. All requests by default.
  final bool Function(http.BaseRequest request)? shouldLog;

  /// Returns whether a response is an image, in addition to the `Content-Type: image/*` check.
  final bool Function(http.BaseRequest request, http.BaseResponse response)? isImage;

  FloconNetworkPlugin? get _network => _plugin ?? Flocon.networkPlugin;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final plugin = _network;
    if (plugin == null || !(shouldLog?.call(request) ?? true)) {
      return _inner.send(request);
    }

    final callId = const Uuid().v4();
    final stopwatch = Stopwatch()..start();
    try {
      final body = request is http.Request ? (request.body.isEmpty ? null : request.body) : null;
      plugin.logRequest(
        callId: callId,
        url: request.url.toString(),
        method: request.method,
        startTime: DateTime.now().millisecondsSinceEpoch,
        requestHeaders: Map.of(request.headers),
        requestBody: request is http.MultipartRequest ? _describeMultipart(request) : body,
        requestSize: body == null ? request.contentLength : utf8.encode(body).length,
      );
    } catch (_) {}

    final http.StreamedResponse streamed;
    try {
      streamed = await _inner.send(request);
    } catch (e) {
      _safe(() => plugin.logResponse(
            callId: callId,
            durationMs: stopwatch.elapsedMicroseconds / 1000,
            error: e.toString(),
          ));
      rethrow;
    }

    // The body must be read to be logged: buffer it and hand back an equivalent response.
    final bytes = await streamed.stream.toBytes();
    _safe(() {
      final contentType = streamed.headers['content-type'];
      final image = (contentType?.toLowerCase().startsWith('image/') ?? false) ||
          (isImage?.call(request, streamed) ?? false);
      plugin.logResponse(
        callId: callId,
        durationMs: stopwatch.elapsedMicroseconds / 1000,
        httpCode: streamed.statusCode,
        contentType: contentType,
        body: image ? null : utf8.decode(bytes, allowMalformed: true),
        headers: Map.of(streamed.headers),
        size: bytes.length,
        requestHeaders: Map.of(request.headers),
        isImage: image,
      );
    });

    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      streamed.statusCode,
      contentLength: bytes.length,
      request: streamed.request,
      headers: streamed.headers,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  static void _safe(void Function() f) {
    try {
      f();
    } catch (_) {}
  }

  static String _describeMultipart(http.MultipartRequest r) {
    final fields = r.fields.entries.map((e) => '${e.key}=${e.value}');
    final files = r.files.map((f) => '${f.field}=<file ${f.filename}>');
    return [...fields, ...files].join('&');
  }
}
