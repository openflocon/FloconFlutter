import 'package:flocon/flocon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flocon calls are no-ops before initialize', () async {
    expect(Flocon.isInitialized, isFalse);
    expect(Flocon.isConnected, isFalse);
    expect(Flocon.connectionState, isA<FloconIdle>());
    expect(
      await Flocon.connect('192.168.1.20'),
      isA<FloconConnectResultNotStarted>(),
    );
    await Flocon.disconnect();
  });
}
