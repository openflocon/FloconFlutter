import 'package:flocon/flocon.dart';
import 'package:flocon_qr_scanner/flocon_qr_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects to the trimmed address and returns the result', () async {
    final addresses = <String>[];
    final connector = FloconQrConnector(connect: (a) async {
      addresses.add(a);
      return const FloconConnectResultConnected();
    });
    expect(await connector.handle(' 192.168.1.20:10023:10024\n'), isA<FloconConnectResultConnected>());
    expect(addresses, ['192.168.1.20:10023:10024']);
  });

  test('ignores empty scans', () async {
    final connector = FloconQrConnector(connect: (_) async => fail('must not connect'));
    expect(await connector.handle(null), isNull);
    expect(await connector.handle('  '), isNull);
  });

  test('ignores scans while one is in progress, then tries again after a failure', () async {
    var calls = 0;
    final connector = FloconQrConnector(
      retryDelay: const Duration(milliseconds: 30),
      connect: (_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const FloconConnectResultFailed('nope');
      },
    );
    final first = connector.handle('1.2.3.4');
    expect(await connector.handle('1.2.3.4'), isNull); // busy
    expect(await first, isA<FloconConnectResultFailed>());
    expect(await connector.handle('1.2.3.4'), isA<FloconConnectResultFailed>());
    expect(calls, 2);
  });

  test('a connection that throws becomes a failed result', () async {
    final connector = FloconQrConnector(
      retryDelay: Duration.zero,
      connect: (_) async => throw StateError('boom'),
    );
    expect(await connector.handle('1.2.3.4'), isA<FloconConnectResultFailed>());
  });

  test('once connected, it stops connecting', () async {
    var calls = 0;
    final connector = FloconQrConnector(connect: (_) async {
      calls++;
      return const FloconConnectResultConnected();
    });
    await connector.handle('1.2.3.4');
    expect(await connector.handle('1.2.3.4'), isNull);
    expect(calls, 1);
  });
}
