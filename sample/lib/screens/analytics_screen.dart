import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import 'actions_view.dart';

/// One stream per analytics provider: each stream is its own table in the desktop app.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static Future<String> _log(String stream, String event, Map<String, String> props) async {
    floconAnalytics(stream).logEvents([
      AnalyticsEvent(
        eventName: event,
        properties: [for (final e in props.entries) AnalyticsProperty(e.key, e.value)],
      ),
    ]);
    return 'sent on "$stream"';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: ActionsView(actions: [
          SampleAction('firebase: button_clicked', () => _log('firebase', 'button_clicked', {'button_id': 'sample', 'at': DateTime.now().toIso8601String()})),
          SampleAction('firebase: screen_view', () => _log('firebase', 'screen_view', {'screen': 'AnalyticsScreen'})),
          SampleAction('amplitude: purchase', () => _log('amplitude', 'purchase', {'sku': 'pro_monthly', 'price': '9.99'})),
          SampleAction('Batch of 3 events', () async {
            floconAnalytics('firebase').logEvents([
              for (var i = 1; i <= 3; i++) AnalyticsEvent(eventName: 'batch_event', properties: [AnalyticsProperty('index', '$i')]),
            ]);
            return 'sent';
          }),
        ]),
      );
}
