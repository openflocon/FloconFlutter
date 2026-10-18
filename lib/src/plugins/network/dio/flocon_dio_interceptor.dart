import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../flocon.dart';
import '../network_options.dart';
import '../network_plugin.dart';

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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final plugin = _network;
      if (plugin != null && (networkOptions.shouldLog?.call(options) ?? true)) {
        final callId = const Uuid().v4();
        final startMs = DateTime.now().millisecondsSinceEpoch;
        options.extra[_extraKey] = _Call(callId, Stopwatch()..start());
        final body = _encodeBody(options.data);
        plugin.logRequest(
          callId: callId,
          url: options.uri.toString(),
          method: options.method,
          startTime: startMs,
          requestHeaders: _headers(options.headers),
          requestBody: body,
          requestSize: body == null ? null : utf8.encode(body).length,
        );
      }
    } catch (_) {}
    handler.next(options);
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
