import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'actions_view.dart';

/// The SharedPreferences are listed in the Preferences section of Flocon,
/// where String, bool, int, double and string-list values can be edited.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final Future<SharedPreferences> _prefs = _init();

  Future<SharedPreferences> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', prefs.getString('username') ?? 'Florent');
    await prefs.setBool('dark_mode', prefs.getBool('dark_mode') ?? false);
    await prefs.setInt('launch_count', (prefs.getInt('launch_count') ?? 0) + 1);
    await prefs.setDouble('volume', prefs.getDouble('volume') ?? 0.8);
    await prefs.setStringList('tags', prefs.getStringList('tags') ?? ['flutter', 'flocon']);
    floconRegisterSharedPreferences(prefs);
    return prefs;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Preferences')),
        body: FutureBuilder<SharedPreferences>(
          future: _prefs,
          builder: (context, snapshot) {
            final prefs = snapshot.data;
            if (prefs == null) return const Center(child: CircularProgressIndicator());
            return ActionsView(actions: [
              SampleAction('Increment launch_count', () async {
                await prefs.reload();
                final value = (prefs.getInt('launch_count') ?? 0) + 1;
                await prefs.setInt('launch_count', value);
                return 'launch_count = $value (reopen the store in Flocon to refresh)';
              }),
              SampleAction('Read current values', () async {
                await prefs.reload();
                return {for (final k in prefs.getKeys()) k: prefs.get(k)}.toString();
              }),
            ]);
          },
        ),
      );
}
