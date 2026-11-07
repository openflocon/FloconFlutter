import 'package:flocon/flocon.dart';
import 'package:flutter_test/flutter_test.dart';

FloconAddress parse(String s) =>
    FloconAddress.parse(s, webSocketPort: 9023, httpPort: 9024);

void main() {
  test('a host alone takes the default ports', () {
    expect(parse('192.168.1.20').toString(), '192.168.1.20:9023:9024');
    expect(parse(' my-mac.local ').host, 'my-mac.local');
  });

  test('host:ws and host:ws:http', () {
    expect(parse('192.168.1.20:10023').toString(), '192.168.1.20:10023:9024');
    expect(
      parse('192.168.1.20:10023:10024').toString(),
      '192.168.1.20:10023:10024',
    );
  });

  test('invalid addresses throw a readable error', () {
    for (final bad in [
      '',
      '  ',
      'http://192.168.1.20',
      '192.168.1.20/path',
      '192.168.1.20?x',
      '192.168.1.20 1',
      ':9023',
      'a:1:2:3',
      'a:',
      'a:0',
      'a:65536',
      'a:0009023',
      'a:12ab',
      'a:1::2',
    ]) {
      expect(() => parse(bad), throwsA(isA<FloconAddressError>()), reason: bad);
    }
  });

  test('uris and stored form', () {
    final a = parse('10.0.0.2:10023:10024');
    expect(a.webSocketUri.toString(), 'wss://10.0.0.2:10023');
    expect(a.uploadUri.toString(), 'https://10.0.0.2:10024/upload');
    expect(
      a.stored(webSocketPort: 9023, httpPort: 9024),
      '10.0.0.2:10023:10024',
    );
    expect(
      parse('10.0.0.2').stored(webSocketPort: 9023, httpPort: 9024),
      '10.0.0.2',
    );
    expect(parse('10.0.0.2'), parse('10.0.0.2:9023:9024'));
  });

  test(
    'ports of the config outside 1...65535 are replaced by the defaults',
    () {
      final config = const FloconConfig(
        webSocketPort: 0,
        httpPort: 70000,
        bufferCapacity: 0,
      ).sanitized();
      expect(
        (config.webSocketPort, config.httpPort, config.bufferCapacity),
        (9023, 9024, 5000),
      );
    },
  );
}
