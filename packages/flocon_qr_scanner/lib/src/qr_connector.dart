import 'package:flocon/flocon.dart';

/// Connects to the address a QR code holds, one scan at a time.
///
/// The QR code of Flocon Desktop holds the IP address of the computer, such as `192.168.1.20`, followed by both
/// ports (`192.168.1.20:10023:10024`) when they are not the defaults.
class FloconQrConnector {
  FloconQrConnector({
    Future<FloconConnectResult> Function(String address)? connect,
    this.retryDelay = const Duration(seconds: 2),
  }) : _connect = connect ?? Flocon.connect;

  final Future<FloconConnectResult> Function(String address) _connect;

  /// After a failure, the same code is not tried again before this delay (the camera keeps reading it).
  final Duration retryDelay;

  var _busy = false;

  /// Returns the result of the connection, or null if the scan was ignored (empty, or one is in progress).
  Future<FloconConnectResult?> handle(String? scanned) async {
    final text = scanned?.trim();
    if (text == null || text.isEmpty || _busy) return null;
    _busy = true;
    FloconConnectResult result;
    try {
      result = await _connect(text);
    } catch (e) {
      result = FloconConnectResultFailed('$e');
    }
    if (result is FloconConnectResultConnected) return result; // stays busy: connected, nothing more to scan
    await Future<void>.delayed(retryDelay);
    _busy = false;
    return result;
  }
}
