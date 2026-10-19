import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'crash_screen.dart';
import 'dio_screen.dart';
import 'http_screen.dart';
import 'image_screen.dart';
import 'mocks_screen.dart';
import 'preferences_screen.dart';
import 'table_screen.dart';
import 'web_socket_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Text('Flocon Flutter sample')),
      body: ListView(children: [
        ListTile(leading: const Icon(Icons.cloud_outlined), title: const Text('Dio'), subtitle: const Text('HTTP calls with FloconDioInterceptor'), onTap: () => open(const DioScreen())),
        ListTile(leading: const Icon(Icons.http), title: const Text('package:http'), subtitle: const Text('HTTP calls with FloconHttpClient'), onTap: () => open(const HttpScreen())),
        ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Images'), subtitle: const Text('Download and display images'), onTap: () => open(const ImageScreen())),
        ListTile(leading: const Icon(Icons.science_outlined), title: const Text('Mocks and bad network'), subtitle: const Text('Try the mocks and the simulation set from the desktop'), onTap: () => open(const MocksScreen())),
        ListTile(leading: const Icon(Icons.sync_alt), title: const Text('WebSocket'), subtitle: const Text('Manual WebSocket event logging'), onTap: () => open(const WebSocketScreen())),
        ListTile(leading: const Icon(Icons.analytics_outlined), title: const Text('Analytics'), subtitle: const Text('Events on streams, one table per stream'), onTap: () => open(const AnalyticsScreen())),
        ListTile(leading: const Icon(Icons.tune), title: const Text('Preferences'), subtitle: const Text('SharedPreferences, editable from the desktop'), onTap: () => open(const PreferencesScreen())),
        ListTile(leading: const Icon(Icons.bug_report_outlined), title: const Text('Crash reporter'), subtitle: const Text('Throw errors reported to Flocon'), onTap: () => open(const CrashScreen())),
        ListTile(leading: const Icon(Icons.table_chart_outlined), title: const Text('Tables'), subtitle: const Text('Rows of structured data'), onTap: () => open(const TableScreen())),
      ]),
    );
  }
}
