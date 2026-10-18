import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import 'actions_view.dart';

/// Columns are created from the names used in the logged rows.
class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tables')),
        body: ActionsView(actions: [
          SampleAction('users: add a row', () async {
            _count++;
            floconTable('users').log([
              TableColumnConfig('name', 'User $_count'),
              TableColumnConfig('age', '${20 + _count}'),
            ]);
            return 'row $_count sent';
          }),
          SampleAction('settings: add a row', () async {
            floconTable('settings').log([
              const TableColumnConfig('key', 'dark_mode'),
              TableColumnConfig('value', DateTime.now().second.isEven ? 'true' : 'false'),
              const TableColumnConfig('source', 'sample'),
            ]);
            return 'sent';
          }),
        ]),
      );
}
