import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Object body})>[];
  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) => sent.add((
    plugin: plugin,
    method: method,
    body: jsonDecode(body) as Object,
  ));
}

void main() {
  test('analytics sends one JSON array on plugin Analytics', () {
    final s = _Sender();
    FloconAnalyticsPlugin(sender: s).registerAnalytics('firebase', [
      const AnalyticsEvent(
        eventName: 'click',
        properties: [AnalyticsProperty('id', 'pay')],
      ),
      const AnalyticsEvent(eventName: 'view'),
    ]);
    final m = s.sent.single;
    expect((m.plugin, m.method), ('analytics', 'add_items'));
    final items = m.body as List;
    expect(items, hasLength(2));
    expect(items[0]['analytics_table_id'], 'firebase');
    expect(items[0]['properties'], [
      {'name': 'id', 'value': 'pay'},
    ]);
    expect(items[0].keys.toSet(), {'id', 'analytics_table_id', 'event_name', 'created_at', 'properties'});
    expect(items[1]['properties'], isEmpty);
  });

  test('analytics ignores empty lists', () {
    final s = _Sender();
    FloconAnalyticsPlugin(sender: s).registerAnalytics('x', []);
    expect(s.sent, isEmpty);
  });

  test('table sends a one-element JSON array on plugin Table', () {
    final s = _Sender();
    FloconTablePlugin(sender: s).registerTable('users', [
      const TableColumnConfig('name', 'Florent'),
    ], id: 'r1');
    final m = s.sent.single;
    expect((m.plugin, m.method), ('table', 'add_items'));
    final row = (m.body as List).single;
    expect(row['id'], 'r1');
    expect(row['name'], 'users');
    expect(row['columns'], [
      {'column': 'name', 'value': 'Florent'},
    ]);
  });

  test('helpers are no-ops before initialize', () {
    floconAnalytics('x').logEvents([const AnalyticsEvent(eventName: 'e')]);
    floconTable('t').log([const TableColumnConfig('a', 'b')]);
  });
}
