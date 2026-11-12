import 'package:flocon/flocon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_plugin.dart';
import 'shared_preferences_store.dart';

/// The Preferences plugin, to install with `startFlocon`: shows [prefs] in the Flocon desktop app, where its values
/// can be edited.
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// await startFlocon((flocon) => flocon..install(FloconSharedPreferences(prefs)));
/// ```
///
/// Register other instances later with [floconRegisterSharedPreferences].
class FloconSharedPreferences extends FloconPluginFactory {
  const FloconSharedPreferences(this.prefs, {this.name = 'SharedPreferences'});

  final SharedPreferences prefs;

  /// The name of the store in the desktop app.
  final String name;

  @override
  Future<void> install() async => floconRegisterSharedPreferences(prefs, name: name);
}

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
