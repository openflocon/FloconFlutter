import 'dart:convert';
import 'dart:math';

/// How an app-side error is reproduced, derived from the exception class name sent by the desktop
/// (Java names such as `java.net.SocketTimeoutException`).
enum FloconErrorKind { timeout, connection, unknown }

FloconErrorKind floconErrorKindOf(String className) {
  final name = className.toLowerCase();
  if (name.contains('timeout')) return FloconErrorKind.timeout;
  if (name.contains('socket') ||
      name.contains('connect') ||
      name.contains('unknownhost') ||
      name.contains('ssl') ||
      name.contains('eof')) {
    return FloconErrorKind.connection;
  }
  return FloconErrorKind.unknown;
}

/// What an HTTP adapter must return instead of performing the real call.
sealed class FloconNetworkOverride {
  const FloconNetworkOverride({required this.isMocked});

  /// True for a mock, false for a simulated bad connection.
  final bool isMocked;
}

/// A fake HTTP response.
class FloconFakeResponse extends FloconNetworkOverride {
  const FloconFakeResponse({
    required this.statusCode,
    required this.body,
    required this.mediaType,
    required this.headers,
    required super.isMocked,
  });

  final int statusCode;
  final String body;
  final String mediaType;
  final Map<String, String> headers;

  /// The headers, with the content type when the mock defines one and the headers do not.
  Map<String, String> get headersWithContentType {
    final hasContentType = headers.keys.any(
      (k) => k.toLowerCase() == 'content-type',
    );
    return {
      ...headers,
      if (!hasContentType && mediaType.isNotEmpty) 'content-type': mediaType,
    };
  }
}

/// A fake network error, to be thrown in the way of the HTTP library.
class FloconFakeError extends FloconNetworkOverride {
  FloconFakeError({required this.className, required super.isMocked})
    : kind = floconErrorKindOf(className);

  /// The exception class sent by the desktop, for example `java.net.SocketTimeoutException`.
  final String className;
  final FloconErrorKind kind;
}

/// A mock configured from the desktop: answers the matching calls instead of the network.
class FloconMock {
  const FloconMock({
    required this.urlPattern,
    required this.method,
    required this.delay,
    this.httpCode,
    this.body = '',
    this.mediaType = '',
    this.headers = const {},
    this.errorException,
  });

  factory FloconMock.fromJson(Map<String, dynamic> json) {
    final expectation = json['expectation'] as Map<String, dynamic>;
    final response = json['response'] as Map<String, dynamic>;
    return FloconMock(
      urlPattern: expectation['urlPattern'] as String,
      method: expectation['method'] as String,
      delay: Duration(milliseconds: (response['delay'] as num?)?.toInt() ?? 0),
      httpCode: (response['httpCode'] as num?)?.toInt(),
      body: (response['body'] as String?) ?? '',
      mediaType: (response['mediaType'] as String?) ?? '',
      headers: ((response['headers'] as Map?) ?? const {}).map(
        (k, v) => MapEntry('$k', '$v'),
      ),
      errorException: response['errorException'] as String?,
    );
  }

  /// A regular expression that must match the whole url.
  final String urlPattern;

  /// `GET`, `POST`... or `*`.
  final String method;
  final Duration delay;
  final int? httpCode;
  final String body;
  final String mediaType;
  final Map<String, String> headers;
  final String? errorException;

  bool matches(String url, String method) {
    final methodMatches =
        this.method == '*' || this.method.toLowerCase() == method.toLowerCase();
    if (!methodMatches) return false;
    try {
      return RegExp('^(?:$urlPattern)\$').hasMatch(url);
    } catch (_) {
      return false; // invalid pattern
    }
  }

  FloconNetworkOverride? toOverride() {
    if (errorException != null) {
      return FloconFakeError(className: errorException!, isMocked: true);
    }
    if (httpCode == null) return null;
    return FloconFakeResponse(
      statusCode: httpCode!,
      body: body,
      mediaType: mediaType,
      headers: headers,
      isMocked: true,
    );
  }
}

/// Parses the `setup_mocks` message. Unreadable input gives no mock.
List<FloconMock> parseMocks(String json) {
  try {
    final mocks = <FloconMock>[];
    for (final item in jsonDecode(json) as List<dynamic>) {
      final mock = FloconMock.fromJson(item as Map<String, dynamic>);
      if (mock.toOverride() != null) mocks.add(mock);
    }
    return mocks;
  } catch (_) {
    return const [];
  }
}

/// A bad network simulation: random latency and random errors.
class FloconBadQualityConfig {
  const FloconBadQualityConfig({
    required this.latencyTriggerProbability,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.errorProbability,
    required this.errors,
  });

  factory FloconBadQualityConfig.fromJson(Map<String, dynamic> json) {
    final latency = json['latency'] as Map<String, dynamic>;
    return FloconBadQualityConfig(
      latencyTriggerProbability: (latency['latencyTriggerProbability'] as num)
          .toDouble(),
      minLatencyMs: (latency['minLatencyMs'] as num).toInt(),
      maxLatencyMs: (latency['maxLatencyMs'] as num).toInt(),
      errorProbability: (json['errorProbability'] as num).toDouble(),
      errors: [
        for (final e
            in (json['errors'] as List<dynamic>).cast<Map<String, dynamic>>())
          FloconBadQualityError(
            weight: (e['weight'] as num).toDouble(),
            errorCode: (e['errorCode'] as num?)?.toInt() ?? 0,
            errorBody: (e['errorBody'] as String?) ?? '',
            errorContentType: (e['errorContentType'] as String?) ?? '',
            errorException: (e['errorException'] as String?)?.isEmpty ?? true
                ? null
                : e['errorException'] as String,
          ),
      ],
    );
  }

  final double latencyTriggerProbability;
  final int minLatencyMs;
  final int maxLatencyMs;
  final double errorProbability;
  final List<FloconBadQualityError> errors;

  bool shouldSimulateLatency(Random random) =>
      latencyTriggerProbability > 0 &&
      (latencyTriggerProbability >= 1 ||
          random.nextDouble() < latencyTriggerProbability);

  Duration randomLatency(Random random) {
    final max = maxLatencyMs < minLatencyMs ? minLatencyMs : maxLatencyMs;
    return Duration(
      milliseconds: minLatencyMs + random.nextInt(max - minLatencyMs + 1),
    );
  }

  bool shouldFail(Random random) =>
      errorProbability > 0 && random.nextDouble() < errorProbability;

  /// Picks an error, the more likely the bigger its weight.
  FloconBadQualityError? selectRandomError(Random random) {
    if (errors.isEmpty) return null;
    final total = errors.fold<double>(0, (sum, e) => sum + e.weight);
    var pick = random.nextDouble() * total;
    for (final error in errors) {
      pick -= error.weight;
      if (pick <= 0) return error;
    }
    return errors.first;
  }
}

class FloconBadQualityError {
  const FloconBadQualityError({
    required this.weight,
    required this.errorCode,
    required this.errorBody,
    required this.errorContentType,
    this.errorException,
  });

  final double weight;
  final int errorCode;
  final String errorBody;
  final String errorContentType;

  /// When set, the call throws this exception instead of returning an HTTP error.
  final String? errorException;

  FloconNetworkOverride toOverride() => errorException != null
      ? FloconFakeError(className: errorException!, isMocked: false)
      : FloconFakeResponse(
          statusCode: errorCode,
          body: errorBody,
          mediaType: errorContentType,
          headers: const {},
          isMocked: false,
        );
}

/// Parses the `setupBadNetworkConfig` message. Unreadable input gives no configuration.
FloconBadQualityConfig? parseBadQualityConfig(String json) {
  try {
    return FloconBadQualityConfig.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  } catch (_) {
    return null;
  }
}
