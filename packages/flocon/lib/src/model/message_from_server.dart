/// A message sent by the Flocon desktop app to a plugin.
class FloconMessageFromServer {
  const FloconMessageFromServer({
    required this.plugin,
    required this.method,
    required this.body,
  });

  factory FloconMessageFromServer.fromJson(Map<String, dynamic> json) =>
      FloconMessageFromServer(
        plugin: json['plugin'] as String,
        method: json['method'] as String,
        body: (json['body'] as String?) ?? '',
      );

  final String plugin;
  final String method;
  final String body;
}
