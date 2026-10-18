import 'package:flocon/flocon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_plugin.dart';
import 'shared_preferences_store.dart';

/// Shows a [SharedPreferences] instance in the Preferences section of the Flocon desktop app.
/// Values of type `String`, `bool`, `int`, `double` and `List<String>` can be edited from the desktop.
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// floconRegisterSharedPreferences(prefs);
/// ```
///
/// Does nothing if `Flocon.initialize` has not been called.
void floconRegisterSharedPreferences(SharedPreferences prefs, {String name = 'SharedPreferences'}) {
  final sender = Flocon.messageSender;
  if (sender == null) return;
  var plugin = Flocon.plugin<FloconPreferencesPlugin>();
  if (plugin == null) {
    plugin = FloconPreferencesPlugin(sender: sender);
    Flocon.register(plugin);
  }
  plugin.registerAndNotify(SharedPreferencesStore(prefs, name));
}
