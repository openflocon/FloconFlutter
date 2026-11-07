import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';
import 'package:flocon_database/flocon_database.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/analytics_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/crash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/database_screen.dart';
import 'screens/deeplinks_screen.dart';
import 'screens/feature_flags_screen.dart';
import 'screens/files_screen.dart';
import 'screens/home_screen.dart';
import 'screens/images_screen.dart';
import 'screens/network_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/timeline_screen.dart';
import 'startup/sample_state.dart';
import 'theme/sample_screen.dart';
import 'theme/sample_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Flocon.isLoggingEnabled = kDebugMode;
  // Android emulator reaches the host machine through 10.0.2.2.
  // On a physical device, use Flocon.connect (or scan the QR code) with the local IP of the computer running Flocon.
  Flocon.initialize(config: FloconConfig(host: Platform.isAndroid ? '10.0.2.2' : 'localhost'));
  await floconEnableFilesPlugin();
  await floconEnableDatabasePlugin();
  await floconEnableCrashReporter();
  FloconLifecycleObserver.start();
  await SampleStartup.run();
  floconRegisterSharedPreferences(await SharedPreferences.getInstance());
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  static const _screens = <SampleScreen, Widget>{
    SampleScreen.network: NetworkScreen(),
    SampleScreen.database: DatabaseScreen(),
    SampleScreen.analytics: AnalyticsScreen(),
    SampleScreen.featureFlags: FeatureFlagsScreen(),
    SampleScreen.preferences: PreferencesScreen(),
    SampleScreen.files: FilesScreen(),
    SampleScreen.dashboard: DashboardScreen(),
    SampleScreen.deeplinks: DeeplinksScreen(),
    SampleScreen.timeline: TimelineScreen(),
    SampleScreen.images: ImagesScreen(),
    SampleScreen.crash: CrashScreen(),
  };

  Route<void>? _route(RouteSettings settings) {
    final name = settings.name ?? '/';
    Widget? page;
    if (name == '/') {
      page = const HomeScreen();
    } else if (name == '/connection') {
      page = const ConnectionScreen();
    } else if (name.startsWith('/user/')) {
      page = DeeplinkDestinationScreen(title: 'User', lines: ['Profile of ${name.substring(6)}']);
    } else if (name.startsWith('/post/')) {
      page = DeeplinkDestinationScreen(title: 'Post', lines: ['Post ${name.substring(6)}', 'Comment: ${settings.arguments ?? '(none)'}']);
    } else if (name.startsWith('/settings/')) {
      page = DeeplinkDestinationScreen(title: 'Settings', lines: ['Environment: ${name.substring(10)}']);
    } else {
      for (final entry in _screens.entries) {
        if (entry.key.route == name) page = entry.value;
      }
    }
    return page == null ? null : MaterialPageRoute<void>(settings: settings, builder: (_) => page!);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flocon Sample',
        debugShowCheckedModeBanner: false,
        theme: SampleTheme.data,
        navigatorKey: SampleDeeplinks.navigatorKey,
        // the screen changes appear in the Flocon timeline
        navigatorObservers: [FloconNavigatorObserver()],
        onGenerateRoute: _route,
      );
}
