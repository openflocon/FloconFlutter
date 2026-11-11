/// An open connection to the desktop app, whatever the platform transport is.
abstract interface class FloconSocketConnection {
  /// Throws if the connection is closed.
  void send(String message);

  /// Starts delivering the text messages. [onClosed] is called once, on a close or an error.
  void listen({
    required void Function(String) onMessage,
    required void Function(Object? error) onClosed,
  });

  Future<void> close();
}
