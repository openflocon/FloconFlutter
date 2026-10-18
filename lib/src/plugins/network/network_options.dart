import 'package:dio/dio.dart';

/// Options of the network interception.
class FloconNetworkOptions {
  const FloconNetworkOptions({this.shouldLog, this.isImage});

  /// Returns whether a request is sent to the desktop app. All requests by default.
  final bool Function(RequestOptions request)? shouldLog;

  /// Returns whether a response is an image, in addition to the `Content-Type: image/*` check.
  /// The body of an image is not sent: the desktop downloads it from its URL.
  final bool Function(RequestOptions request, Response<dynamic> response)? isImage;
}
