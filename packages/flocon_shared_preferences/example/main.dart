import 'package:flocon/flocon.dart';
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    final prefs = await SharedPreferences.getInstance();
    await startFlocon((flocon) => flocon..install(FloconSharedPreferences(prefs)));
  }
}
