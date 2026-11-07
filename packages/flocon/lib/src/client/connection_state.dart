import 'dart:async';

/// The state of the connection to the Flocon desktop app.
sealed class FloconConnectionState {
  const FloconConnectionState();
}

/// The SDK is not started.
class FloconIdle extends FloconConnectionState {
  const FloconIdle();
}

/// Not connected: what the app logs is kept in memory, and sent once a desktop is reachable.
class FloconBuffering extends FloconConnectionState {
  const FloconBuffering();
}

class FloconConnecting extends FloconConnectionState {
  const FloconConnecting();
}

/// Connected: the messages are sent right away.
class FloconConnected extends FloconConnectionState {
  const FloconConnected();
}

/// The last attempt failed. The messages are still kept, and the SDK tries again.
class FloconFailed extends FloconConnectionState {
  const FloconFailed(this.reason);
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is FloconFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// What `Flocon.connect` returns, instead of throwing.
sealed class FloconConnectResult {
  const FloconConnectResult();
}

class FloconConnectResultConnected extends FloconConnectResult {
  const FloconConnectResultConnected();
}

/// `Flocon.initialize` has not been called.
class FloconConnectResultNotStarted extends FloconConnectResult {
  const FloconConnectResultNotStarted();
}

class FloconConnectResultInvalidAddress extends FloconConnectResult {
  const FloconConnectResultInvalidAddress(this.reason);
  final String reason;
}

/// The connection could not be opened. The messages are kept, call `connect` again to retry.
class FloconConnectResultFailed extends FloconConnectResult {
  const FloconConnectResultFailed(this.reason);
  final String reason;
}

/// Keeps the state of every link, and publishes the one of the SDK: connected as soon as one is,
/// else connecting, else failed, else the first one.
class FloconConnectionStateStore {
  final _states = <int, FloconConnectionState>{};
  final _controller = StreamController<FloconConnectionState>.broadcast(
    sync: true,
  );
  FloconConnectionState _state = const FloconIdle();

  FloconConnectionState get state => _state;

  void set(FloconConnectionState state, int link) {
    _states[link] = state;
    _publish();
  }

  void clear(int link) {
    _states.remove(link);
    _publish();
  }

  void _publish() {
    final states = _states.values.toList();
    final next =
        states.whereType<FloconConnected>().firstOrNull ??
        states.whereType<FloconConnecting>().firstOrNull ??
        states.whereType<FloconFailed>().firstOrNull ??
        states.firstOrNull ??
        const FloconIdle();
    if (next == _state ||
        next.runtimeType == _state.runtimeType && next is! FloconFailed) {
      return;
    }
    _state = next;
    _controller.add(next);
  }

  /// Starts with the current state.
  Stream<FloconConnectionState> get stream {
    late StreamController<FloconConnectionState> controller;
    StreamSubscription<FloconConnectionState>? subscription;
    controller = StreamController<FloconConnectionState>(
      onListen: () {
        controller.add(_state);
        subscription = _controller.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}
