/// The address given to `Flocon.connect` cannot be read.
class FloconAddressError implements Exception {
  const FloconAddressError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A desktop app to connect to: its host and the two ports of its servers.
class FloconAddress {
  const FloconAddress({
    required this.host,
    required this.webSocketPort,
    required this.httpPort,
  });

  final String host;
  final int webSocketPort;
  final int httpPort;

  Uri get webSocketUri => Uri(scheme: 'wss', host: host, port: webSocketPort);

  Uri get uploadUri =>
      Uri(scheme: 'https', host: host, port: httpPort, path: '/upload');

  /// Reads [address]: an IP address or a host, with optional ports, such as `192.168.1.20`,
  /// `my-mac.local`, `192.168.1.20:10023` (WebSocket port) or `192.168.1.20:10023:10024`
  /// (WebSocket port, then HTTP port).
  ///
  /// An omitted port takes the given default. Only IPv4 addresses and host names are read: no scheme,
  /// path, query, fragment, whitespace nor IPv6.
  ///
  /// Throws a [FloconAddressError] if the address is empty, has a scheme, a path, more than two ports,
  /// or a port that is not an integer from 1 to 65535 with at most 5 digits.
  factory FloconAddress.parse(
    String address, {
    required int webSocketPort,
    required int httpPort,
  }) {
    final trimmed = address.trim();
    final invalid = FloconAddressError(
      "Cannot read '$address', enter the IP address of the computer, such as 192.168.1.20, "
      'with optional ports, such as 192.168.1.20:10023:10024 (WebSocket port, then HTTP port), '
      'without scheme nor path',
    );
    final forbidden = trimmed.contains(RegExp(r'[/?#\s]'));
    final parts = trimmed.split(':');
    if (trimmed.isEmpty || forbidden || parts.length > 3 || parts.first.isEmpty) {
      throw invalid;
    }

    int port(String text) {
      final value = int.tryParse(text);
      if (text.isEmpty ||
          text.length > 5 ||
          !RegExp(r'^[0-9]+$').hasMatch(text) ||
          value == null ||
          value < 1 ||
          value > 65535) {
        throw FloconAddressError(
          "Cannot read the ports of '$address', each must be an integer from 1 to 65535, with at most 5 digits",
        );
      }
      return value;
    }

    return FloconAddress(
      host: parts.first,
      webSocketPort: parts.length >= 2 ? port(parts[1]) : webSocketPort,
      httpPort: parts.length == 3 ? port(parts[2]) : httpPort,
    );
  }

  /// The address kept for the next launch: the host alone when both ports are the given ones,
  /// otherwise `host:webSocketPort:httpPort`.
  String stored({required int webSocketPort, required int httpPort}) =>
      this.webSocketPort == webSocketPort && this.httpPort == httpPort
      ? host
      : '$host:${this.webSocketPort}:${this.httpPort}';

  @override
  bool operator ==(Object other) =>
      other is FloconAddress &&
      other.host == host &&
      other.webSocketPort == webSocketPort &&
      other.httpPort == httpPort;

  @override
  int get hashCode => Object.hash(host, webSocketPort, httpPort);

  @override
  String toString() => '$host:$webSocketPort:$httpPort';
}
