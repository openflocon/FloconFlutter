import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// The value of one column in a row of a table.
class TableColumnConfig {
  const TableColumnConfig(this.columnName, this.value);
  final String columnName;
  final String value;
}

/// Logs rows in a table of the Flocon desktop app. Columns are created from the names
/// used in the logged rows.
///
/// ```dart
/// floconTable('users').log([TableColumnConfig('name', 'Florent'), TableColumnConfig('age', '33')]);
/// ```
class FloconTable {
  const FloconTable._(this.tableName);
  final String tableName;

  /// Does nothing before [Flocon.initialize].
  void log(List<TableColumnConfig> columns, {String? id}) =>
      Flocon.tablePlugin?.registerTable(tableName, columns, id: id);
}

FloconTable floconTable(String tableName) => FloconTable._(tableName);

/// Sends table rows to the Flocon desktop app.
class FloconTablePlugin implements FloconPlugin {
  FloconTablePlugin({required FloconMessageSender sender}) : _sender = sender;

  static const name = 'table';
  static const methodAddItems = 'add_items';

  final FloconMessageSender _sender;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  void registerTable(
    String tableName,
    List<TableColumnConfig> columns, {
    String? id,
    DateTime? createdAt,
  }) {
    try {
      // the desktop expects a JSON array, even for a single row
      final body = jsonEncode([
        {
          'id': id ?? const Uuid().v4(),
          'name': tableName,
          'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
          'columns': [
            for (final c in columns) {'column': c.columnName, 'value': c.value},
          ],
        },
      ]);
      _sender.send(plugin: pluginName, method: methodAddItems, body: body);
    } catch (_) {}
  }
}
