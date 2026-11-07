import 'dart:collection';
import 'dart:math';

import '../core/logger.dart';

/// A connection to a desktop, as the outbox sees it.
class FloconOutboxLink {
  FloconOutboxLink(this._transport);

  /// Sends a message, returns false if it could not be sent.
  final bool Function(String message) _transport;
  bool isConnected = false;
  String? _pendingHandshake;
  int _cursor = 0;
}

/// Keeps the messages in memory until every desktop it is connected to has received them, in the order
/// they were logged. Up to `capacity` messages are kept: above it, the oldest are dropped.
///
/// A new link receives everything still kept, after its handshake (the first message of a connection).
class FloconOutbox {
  FloconOutbox(int capacity) : _capacity = max(1, capacity);

  final int _capacity;
  final _items = ListQueue<String>();
  var _firstSequence = 0;
  final _links = <FloconOutboxLink>[];

  /// How many messages were dropped because the buffer was full.
  var droppedCount = 0;

  int get bufferedCount => _items.length;

  void add(FloconOutboxLink link) {
    link._cursor = _firstSequence;
    _links.add(link);
  }

  void remove(FloconOutboxLink link) {
    _links.remove(link);
    _trim();
  }

  void enqueue(String message) {
    _items.addLast(message);
    if (_items.length > _capacity) {
      _items.removeFirst();
      _firstSequence++;
      droppedCount++;
      FloconLogger.log('Buffer full, the oldest message was dropped');
    }
    _drain();
  }

  /// The link is connected: [handshake] is sent first, then the messages it did not receive.
  void connected(FloconOutboxLink link, String handshake) {
    link._pendingHandshake = handshake;
    link.isConnected = true;
    _drain();
  }

  void disconnected(FloconOutboxLink link) => link.isConnected = false;

  void _drain() {
    for (final link in List.of(_links)) {
      if (link.isConnected) _drainLink(link);
    }
    _trim();
  }

  void _drainLink(FloconOutboxLink link) {
    while (link.isConnected) {
      // the messages it did not send may have been dropped meanwhile
      link._cursor = max(link._cursor, _firstSequence);
      final handshake = link._pendingHandshake;
      if (handshake != null) {
        if (link._transport(handshake)) {
          link._pendingHandshake = null;
        } else {
          link.isConnected = false;
        }
        continue;
      }
      final index = link._cursor - _firstSequence;
      if (index >= _items.length) return;
      // moves on once sent, so that a failure does not lose the message
      if (link._transport(_items.elementAt(index))) {
        link._cursor++;
      } else {
        link.isConnected = false;
      }
    }
  }

  void _trim() {
    if (_links.isEmpty) return;
    final sentByAll = _links.map((l) => l._cursor).reduce(min);
    while (_firstSequence < sentByAll && _items.isNotEmpty) {
      _items.removeFirst();
      _firstSequence++;
    }
  }
}
