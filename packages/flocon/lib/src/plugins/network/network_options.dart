import '../../flocon.dart';
import '../../start.dart';

/// An HTTP request, as the network options see it, whatever the HTTP library.
class FloconHttpRequest {
  const FloconHttpRequest({required this.url, required this.method, this.headers = const {}});

  final Uri url;
  final String method;
  final Map<String, String> headers;
}

/// An HTTP response, as the network options see it, whatever the HTTP library.
class FloconHttpResponse {
  const FloconHttpResponse({this.statusCode, this.headers = const {}});

  final int? statusCode;

  /// Header names in lower case.
  final Map<String, String> headers;

  String? get contentType => headers['content-type'];
}

/// Options of the network plugin, applied to the calls of every adapter (`withFlocon()` of Dio and `package:http`).
///
/// ```dart
/// startFlocon((flocon) => flocon
///   ..install(FloconNetwork(
///     shouldLog: (request) => request.url.host != 'analytics.example.com',
///     isImage: (request, response) => request.url.host == 'images.example.com',
///   )));
/// ```
class FloconNetwork extends FloconPluginFactory {
  const FloconNetwork({this.shouldLog, this.isImage});

  /// Returns whether a call is sent to the desktop app. All calls by default.
  final bool Function(FloconHttpRequest request)? shouldLog;

  /// Returns whether a response is an image, in addition to the `Content-Type: image/*` check.
  /// The body of an image is not sent: the desktop downloads it from its URL.
  final bool Function(FloconHttpRequest request, FloconHttpResponse response)? isImage;

  @override
  Future<void> install() async => Flocon.networkPlugin?.options = this;
}
