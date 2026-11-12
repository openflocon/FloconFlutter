import 'package:flocon/flocon.dart';
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

/// The SharedPreferences are listed in the Preferences section of Flocon, where String, bool, int, double and string-list
/// values can be edited, and any key deleted.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.preferences, children: [
        SampleSection(title: 'SharedPreferences', children: [
          SampleActionRow(
            title: 'Show in Flocon',
            detail: 'Lists the store, with a string, a bool, an int, a double and a string list',
            buttonTitle: 'Show',
            action: () async {
              final prefs = await SharedPreferences.getInstance();
              Flocon.preferences.register(prefs);
              return '${prefs.getKeys().length} keys';
            },
          ),
          SampleActionRow(
            title: 'Increment launch_count',
            detail: 'Then reopen the store in Flocon to refresh it',
            buttonTitle: 'Increment',
            action: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.reload();
              final value = (prefs.getInt('launch_count') ?? 0) + 1;
              await prefs.setInt('launch_count', value);
              return 'launch_count = $value';
            },
          ),
          SampleActionRow(
            title: 'Read current values',
            detail: 'What the app sees after your edits in Flocon',
            buttonTitle: 'Read',
            action: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.reload();
              return {for (final k in (prefs.getKeys().toList()..sort())) k: prefs.get(k)}.toString();
            },
          ),
        ]),
        const SampleInfoCard('Edit a value in Flocon > Preferences (only a value of the same type is applied), delete a key with a right click, then read the values here.'),
      ]);
}
