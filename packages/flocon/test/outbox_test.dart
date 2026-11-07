import 'package:flocon/src/client/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

class _Peer {
  final received = <String>[];
  var up = true;
  late final link = FloconOutboxLink((m) {
    if (!up) return false;
    received.add(m);
    return true;
  });
}

void main() {
  test(
    'messages are kept until connected, then sent in order after the handshake',
    () {
      final outbox = FloconOutbox(10);
      final peer = _Peer();
      outbox.add(peer.link);
      outbox
        ..enqueue('a')
        ..enqueue('b');
      expect(peer.received, isEmpty);
      outbox.connected(peer.link, 'hello');
      expect(peer.received, ['hello', 'a', 'b']);
      outbox.enqueue('c');
      expect(peer.received, ['hello', 'a', 'b', 'c']);
      expect(outbox.bufferedCount, 0);
    },
  );

  test('the oldest messages are dropped above the capacity', () {
    final outbox = FloconOutbox(3);
    final peer = _Peer();
    outbox.add(peer.link);
    for (var i = 1; i <= 5; i++) {
      outbox.enqueue('$i');
    }
    expect(outbox.droppedCount, 2);
    outbox.connected(peer.link, 'hello');
    expect(peer.received, ['hello', '3', '4', '5']);
  });

  test(
    'after a disconnection, only the missed messages are sent again, after a new handshake',
    () {
      final outbox = FloconOutbox(10);
      final peer = _Peer();
      outbox.add(peer.link);
      outbox.connected(peer.link, 'hello');
      outbox.enqueue('a');
      outbox.disconnected(peer.link);
      outbox.enqueue('b');
      outbox.connected(peer.link, 'hello again');
      expect(peer.received, ['hello', 'a', 'hello again', 'b']);
    },
  );

  test('a failing transport keeps the message and disconnects the link', () {
    final outbox = FloconOutbox(10);
    final peer = _Peer();
    outbox.add(peer.link);
    outbox.connected(peer.link, 'hello');
    peer.up = false;
    outbox.enqueue('a');
    expect(peer.link.isConnected, isFalse);
    expect(outbox.bufferedCount, 1);
    peer.up = true;
    outbox.connected(peer.link, 'hello 2');
    expect(peer.received, ['hello', 'hello 2', 'a']);
  });

  test(
    'every link receives every message, a message is kept until all links got it',
    () {
      final outbox = FloconOutbox(10);
      final a = _Peer(), b = _Peer();
      outbox
        ..add(a.link)
        ..add(b.link);
      outbox.connected(a.link, 'hi a');
      outbox.enqueue('1');
      expect(a.received, ['hi a', '1']);
      expect(outbox.bufferedCount, 1); // b has not got it
      outbox.connected(b.link, 'hi b');
      expect(b.received, ['hi b', '1']);
      expect(outbox.bufferedCount, 0);
    },
  );

  test('removing a link lets the others free the buffer', () {
    final outbox = FloconOutbox(10);
    final a = _Peer(), b = _Peer();
    outbox
      ..add(a.link)
      ..add(b.link);
    outbox.connected(a.link, 'hi');
    outbox.enqueue('1');
    expect(outbox.bufferedCount, 1);
    outbox.remove(b.link);
    expect(outbox.bufferedCount, 0);
  });
}
