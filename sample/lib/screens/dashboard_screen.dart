import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import '../startup/sample_state.dart';
import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';
import '../widgets/sample_widgets.dart';

/// The dashboard "main" is started with the app and shows the user live in Flocon > Dashboard: change it here, or act on it
/// from the desktop (buttons, inputs, form) and watch it change here.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _names = ['Florent', 'David', 'Marie', 'Sophie'];
  var _rows = 0;

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.dashboard, children: [
        SampleSection(title: 'The user of the dashboard', children: [
          ValueListenableBuilder<SampleUser>(
            valueListenable: user,
            builder: (context, u, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${u.status}${u.isPremium ? ' · premium' : ''}', style: const TextStyle(color: SampleTheme.inkMuted)),
              ]),
            ),
          ),
          SampleActionRow(
            title: 'Change user',
            detail: 'Updates the live "User" section',
            buttonTitle: 'Change',
            action: () async {
              final next = _names[(_names.indexOf(user.value.name) + 1) % _names.length];
              user.value = user.value.copyWith(name: next, status: 'active');
              return next;
            },
          ),
        ]),
        SampleSection(title: 'Tables', children: [
          SampleActionRow(
            title: 'Add table row',
            detail: 'Adds a row to the table "sample_users"',
            buttonTitle: 'Add',
            action: () async {
              _rows++;
              Flocon.table.table('sample_users').log([
                TableColumnConfig('name', _names[_rows % _names.length]),
                TableColumnConfig('age', '${20 + _rows}'),
                TableColumnConfig('created', DateTime.now().toIso8601String()),
              ]);
              return 'row $_rows';
            },
          ),
          SampleActionRow(
            title: 'Add a row to another table',
            detail: 'Columns are created from the names you use',
            buttonTitle: 'Add',
            action: () async {
              Flocon.table.table('sample_settings').log([
                const TableColumnConfig('key', 'dark_mode'),
                TableColumnConfig('value', DateTime.now().second.isEven ? 'true' : 'false'),
              ]);
              return null;
            },
          ),
        ]),
        const SampleInfoCard('In Flocon > Dashboard, click Log out, rename the user, tick Premium or submit the form: the callbacks run in this app.', tint: SampleTheme.accent),
      ]);
}
