import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'package:flocon/flocon.dart';
import 'network_options.dart';

/// Dio interceptor that sends every call to the Flocon desktop app.
///
/// ```dart
/// final dio = Dio()..interceptors.add(FloconDioInterceptor());
/// ```
/// Add it last, so it sees the final request and the raw response.
class FloconDioInterceptor extends Interceptor {
  FloconDioInterceptor({this.networkOptions = const FloconNetworkOptions(), FloconNetworkPlugin? plugin})
      : _plugin = plugin;

  final FloconNetworkOptions networkOptions;
  final FloconNetworkPlugin? _plugin;

  static const _extraKey = 'flocon_call';

  FloconNetworkPlugin? get _network => _plugin ?? Flocon.networkPlugin;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    FloconNetworkPlugin? plugin;
    _Call? call;
    FloconNetworkOverride? override;
    try {
      plugin = _network;
      if (plugin != null && (networkOptions.shouldLog?.call(options) ?? true)) {
        final url = options.uri.toString();
        final mock = plugin.findMock(url, options.method);
        final callId = const Uuid().v4();
        final startMs = DateTime.now().millisecondsSinceEpoch;
        call = _Call(callId, Stopwatch()..start());
        options.extra[_extraKey] = call;
        final body = _encodeBody(options.data);
        plugin.logRequest(
          callId: callId,
          url: url,
          method: options.method,
          startTime: startMs,
          requestHeaders: _headers(options.headers),
          requestBody: body,
          requestSize: body == null ? null : utf8.encode(body).length,
          isMocked: mock != null,
        );
        // a mock or a bad network simulation answers instead of the network
        override = await plugin.applyOverride(mock);
      }
    } catch (_) {}

    if (override == null || plugin == null || call == null) {
      handler.next(options);
      return;
    }
    _answer(options, handler, plugin, call, override);
  }

  void _answer(
    RequestOptions options,
    RequestInterceptorHandler handler,
    FloconNetworkPlugin plugin,
    _Call call,
    FloconNetworkOverride override,
  ) {
    switch (override) {
      case FloconFakeError():
        plugin.logResponse(
          callId: call.id,
          durationMs: call.elapsedMs,
          error: override.className,
          isMocked: override.isMocked,
        );
        handler.reject(
          DioException(
            requestOptions: options,
            type: switch (override.kind) {
              FloconErrorKind.timeout => DioExceptionType.connectionTimeout,
              FloconErrorKind.connection => DioExceptionType.connectionError,
              FloconErrorKind.unknown => DioExceptionType.unknown,
            },
            error: override.className,
            message: override.className,
          ),
        );
      case FloconFakeResponse():
        final headers = override.headersWithContentType;
        plugin.logResponse(
          callId: call.id,
          durationMs: call.elapsedMs,
          httpCode: override.statusCode,
          contentType: headers['content-type'],
          body: override.body,
          headers: headers,
          size: utf8.encode(override.body).length,
          requestHeaders: _headers(options.headers),
          isMocked: override.isMocked,
        );
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: override.statusCode,
          data: _decode(override.body, options.responseType),
          headers: Headers.fromMap({for (final e in headers.entries) e.key: [e.value]}),
          isRedirect: false,
        );
        final validate = options.validateStatus;
        if (validate(override.statusCode)) {
          handler.resolve(response);
        } else {
          handler.reject(DioException.badResponse(
            statusCode: override.statusCode,
            requestOptions: options,
            response: response,
          ));
        }
    }
  }

  /// The body of a fake response, in the shape Dio would have produced for `responseType`.
  static dynamic _decode(String body, ResponseType type) {
    switch (type) {
      case ResponseType.bytes:
        return utf8.encode(body);
      case ResponseType.plain:
      case ResponseType.stream:
        return body;
      case ResponseType.json:
        if (body.isEmpty) return body;
        try {
          return jsonDecode(body);
        } catch (_) {
          return body;
        }
    }
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    try {
      final call = response.requestOptions.extra[_extraKey] as _Call?;
      final plugin = _network;
      if (call != null && plugin != null) {
        final contentType = response.headers.value('content-type');
        var isImage = contentType?.toLowerCase().startsWith('image/') ?? false;
        if (!isImage) {
          isImage = networkOptions.isImage?.call(response.requestOptions, response) ?? false;
        }
        final body = isImage ? null : _encodeBody(response.data);
        plugin.logResponse(
          callId: call.id,
          durationMs: call.elapsedMs,
          httpCode: response.statusCode,
          contentType: contentType,
          body: body,
          headers: _responseHeaders(response.headers),
          size: body == null ? null : utf8.encode(body).length,
          requestHeaders: _headers(response.requestOptions.headers),
          isImage: isImage,
        );
      }
    } catch (_) {}
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      final call = err.requestOptions.extra[_extraKey] as _Call?;
      final plugin = _network;
      if (call != null && plugin != null) {
        final response = err.response;
        final body = response == null ? null : _encodeBody(response.data);
        plugin.logResponse(
          callId: call.id,
          durationMs: call.elapsedMs,
          httpCode: response?.statusCode,
          contentType: response?.headers.value('content-type'),
          body: body,
          headers: response == null ? const {} : _responseHeaders(response.headers),
          size: body == null ? null : utf8.encode(body).length,
          error: response == null ? '${err.type.name}: ${err.message ?? err.error}' : null,
          requestHeaders: _headers(err.requestOptions.headers),
        );
      }
    } catch (_) {}
    handler.next(err);
  }

  static Map<String, String> _headers(Map<String, dynamic> headers) =>
      headers.map((k, v) => MapEntry(k, v.toString()));

  static Map<String, String> _responseHeaders(Headers headers) =>
      headers.map.map((k, v) => MapEntry(k, v.join(', ')));

  static String? _encodeBody(Object? data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}=${e.value}').join('&');
      final files = data.files.map((e) => '${e.key}=<file ${e.value.filename}>').join('&');
      return [fields, files].where((s) => s.isNotEmpty).join('&');
    }
    if (data is List<int>) return '<${data.length} bytes>';
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }
}

class _Call {
  _Call(this.id, this.stopwatch);
  final String id;
  final Stopwatch stopwatch;
  double get elapsedMs => stopwatch.elapsedMicroseconds / 1000;
}
