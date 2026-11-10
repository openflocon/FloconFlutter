import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:flocon/flocon.dart';

/// Sends the calls of a `package:http` client to the Flocon desktop app.
extension FloconHttp on http.Client {
  /// Wraps this client in a [FloconHttpClient]:
  ///
  /// ```dart
  /// final client = http.Client().withFlocon();
  /// final response = await client.get(Uri.parse('https://example.com'));
  /// ```
  ///
  /// The options (`shouldLog`, `isImage`) are those of `FloconNetwork`, installed with `startFlocon`.
  FloconHttpClient withFlocon() => FloconHttpClient(this);
}

/// `package:http` client wrapper that sends every call to the Flocon desktop app. Create it with
/// [FloconHttp.withFlocon].
///
/// The calls go through untouched when Flocon is not started.
class FloconHttpClient extends http.BaseClient {
  FloconHttpClient(this._inner, {FloconNetworkPlugin? plugin}) : _plugin = plugin;

  final http.Client _inner;
  final FloconNetworkPlugin? _plugin;

  FloconNetworkPlugin? get _network => _plugin ?? Flocon.networkPlugin;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final plugin = _network;
    if (plugin == null || !plugin.shouldLog(_request(request))) {
      return _inner.send(request);
    }

    final callId = const Uuid().v4();
    final stopwatch = Stopwatch()..start();
    await plugin.ready; // the mocks of the previous launch
    final mock = plugin.findMock(request.url.toString(), request.method);
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
        isMocked: mock != null,
      );
    } catch (_) {}

    // a mock or a bad network simulation answers instead of the network
    FloconNetworkOverride? override;
    try {
      override = await plugin.applyOverride(mock);
    } catch (_) {}
    switch (override) {
      case final FloconFakeError error:
        _safe(() => plugin.logResponse(
              callId: callId,
              durationMs: stopwatch.elapsedMicroseconds / 1000,
              error: error.className,
              isMocked: error.isMocked,
            ));
        throw switch (error.kind) {
          FloconErrorKind.timeout => TimeoutException(error.className),
          _ => http.ClientException(error.className, request.url),
        };
      case final FloconFakeResponse fake:
        final headers = fake.headersWithContentType;
        final bytes = utf8.encode(fake.body);
        _safe(() => plugin.logResponse(
              callId: callId,
              durationMs: stopwatch.elapsedMicroseconds / 1000,
              httpCode: fake.statusCode,
              contentType: headers['content-type'],
              body: fake.body,
              headers: headers,
              size: bytes.length,
              requestHeaders: Map.of(request.headers),
              isMocked: fake.isMocked,
            ));
        return http.StreamedResponse(
          http.ByteStream.fromBytes(bytes),
          fake.statusCode,
          contentLength: bytes.length,
          request: request,
          headers: {for (final e in headers.entries) e.key.toLowerCase(): e.value},
        );
      case null:
        break;
    }

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
      final image = plugin.isImage(
        _request(request),
        FloconHttpResponse(statusCode: streamed.statusCode, headers: streamed.headers),
      );
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

  static FloconHttpRequest _request(http.BaseRequest request) =>
      FloconHttpRequest(url: request.url, method: request.method, headers: request.headers);

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
