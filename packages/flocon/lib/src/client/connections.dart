import 'dart:async';

import '../config.dart';
import '../core/logger.dart';
import 'address.dart';
import 'address_store.dart';
import 'connection_state.dart';
import 'flocon_client.dart';

/// Connects the client to the desktop apps: the default address is always tried, then the address given by the
/// app (or the last one that worked), each retried every [retryDelay] until it is reachable and again when lost.
class FloconConnections {
  FloconConnections({
    required this.client,
    required this.states,
    required this.config,
    this.addressStore,
    this.retryDelay = const Duration(seconds: 3),
  });

  final FloconClient client;
  final FloconConnectionStateStore states;
  final FloconConfig config;
  final FloconAddressStore? addressStore;
  final Duration retryDelay;

  // `connect` and `disconnect` run one after the other.
  Future<void> _lock = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> start() async {
    // the default address (localhost on the simulator) is always tried, whatever the other addresses
    _launch(client.defaultLink);
    final stored = config.rememberLastAddress
        ? await addressStore?.load()
        : null;
    final address = stored ?? config.additionalAddress;
    if (address == null) return;
    try {
      final parsed = _parse(address);
      if (parsed != client.defaultLink.address) {
        _launch(client.addExtraLink(parsed));
      }
    } on FloconAddressError catch (e) {
      FloconLogger.logError("Ignoring the address '$address'", e);
    }
  }

  Future<FloconConnectResult> connect(String address) =>
      _locked(() => _connectLocked(address));

  Future<void> disconnect() => _locked(() async {
    final extra = client.extraLink;
    if (extra != null) await _removeExtraLink(extra);
    await addressStore?.clear();
  });

  Future<FloconConnectResult> _connectLocked(String address) async {
    final FloconAddress parsed;
    try {
      parsed = _parse(address);
    } on FloconAddressError catch (e) {
      return FloconConnectResultInvalidAddress(e.message);
    }
    final defaultLink = client.defaultLink;
    if (parsed == defaultLink.address) {
      return defaultLink.isConnected
          ? const FloconConnectResultConnected()
          : FloconConnectResultFailed(
              '$address is the default address, Flocon is already trying to connect to it',
            );
    }
    final previous = client.extraLink;
    if (previous != null) await _removeExtraLink(previous);
    final link = client.addExtraLink(parsed);
    try {
      await _connectOnce(link);
      return const FloconConnectResultConnected();
    } catch (e) {
      // the messages stay kept for the other addresses, call connect again to retry
      await _removeExtraLink(link);
      return FloconConnectResultFailed(_describe(e));
    }
  }

  FloconAddress _parse(String address) => FloconAddress.parse(
    address,
    webSocketPort: config.webSocketPort,
    httpPort: config.httpPort,
  );

  void _launch(FloconLink link) {
    states.set(const FloconConnecting(), link.id);
    unawaited(_connectUntilSuccess(link));
  }

  Future<void> _connectUntilSuccess(FloconLink link) async {
    while (!link.cancelled) {
      try {
        await _connectOnce(link);
        return;
      } catch (e) {
        if (link.cancelled) return;
        states.set(FloconFailed(_describe(e)), link.id);
        FloconLogger.logError(
          'Cannot connect to ${link.address}, retrying in ${retryDelay.inSeconds}s',
          e,
        );
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  Future<void> _connectOnce(FloconLink link) async {
    states.set(const FloconConnecting(), link.id);
    await client.connect(link, onClosed: () => _connectionLost(link));
    if (link.cancelled) {
      await client.disconnect(link);
      throw StateError('The address was removed');
    }
    states.set(const FloconConnected(), link.id);
    // the address typed by the user, or given at start, comes back at the next launch
    if (!link.isDefault && config.rememberLastAddress) {
      await addressStore?.save(
        link.address.stored(
          webSocketPort: config.webSocketPort,
          httpPort: config.httpPort,
        ),
      );
    }
  }

  void _connectionLost(FloconLink link) {
    if (link.cancelled) return;
    // the messages are kept until the next connection, try again to connect
    states.set(const FloconBuffering(), link.id);
    _launch(link);
  }

  Future<void> _removeExtraLink(FloconLink link) async {
    await client.removeExtraLink(link);
    states.clear(link.id);
  }

  static String _describe(Object error) => error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : '$error';
}
