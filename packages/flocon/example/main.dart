import 'package:flocon/flocon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects in the background to the desktop app (localhost by default), retrying every 3 seconds.
  if (kDebugMode) {
    await startFlocon((flocon) => flocon
      ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'picsum.photos')));
  }

  floconAnalytics('firebase').logEvents([
    AnalyticsEvent(eventName: 'app_started', properties: [AnalyticsProperty('source', 'example')]),
  ]);
  floconTable('users').log([TableColumnConfig('name', 'Ada')]);
  floconTimeline.logLifecycle('started');

  runApp(MaterialApp(
    navigatorObservers: [FloconNavigatorObserver()],
    home: const Scaffold(body: Center(child: Text('Flocon'))),
  ));
}
