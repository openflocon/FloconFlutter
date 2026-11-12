import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';
import '../widgets/sample_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _stream = TextEditingController(text: 'sample');
  final _event = TextEditingController(text: 'button_clicked');
  final _key = TextEditingController(text: 'button_id');
  final _value = TextEditingController(text: 'checkout_pay');

  @override
  void dispose() {
    for (final c in [_stream, _event, _key, _value]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.analytics, children: [
        SampleSection(title: 'Your own event', children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              SampleTextField(controller: _stream, hint: 'Stream (one table per provider)'),
              const SizedBox(height: 10),
              SampleTextField(controller: _event, hint: 'Event name'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SampleTextField(controller: _key, hint: 'Property')),
                const SizedBox(width: 10),
                Expanded(child: SampleTextField(controller: _value, hint: 'Value')),
              ]),
            ]),
          ),
          SampleActionRow(
            title: 'Send',
            detail: 'One event with one property',
            buttonTitle: 'Send',
            action: () async {
              Flocon.analytics.sender(_stream.text).logEvents([
                AnalyticsEvent(eventName: _event.text, properties: [AnalyticsProperty(_key.text, _value.text)]),
              ]);
              return 'sent on "${_stream.text}"';
            },
          ),
        ]),
        SampleSection(title: 'Presets', children: [
          SampleActionRow(
            title: 'Button tapped',
            detail: 'One event in the stream "sample"',
            buttonTitle: 'Send',
            action: () async {
              Flocon.analytics.sender('sample').logEvents([
                AnalyticsEvent(eventName: 'button_tapped', properties: [AnalyticsProperty('at', DateTime.now().toIso8601String())]),
              ]);
              return null;
            },
          ),
          SampleActionRow(
            title: 'Firebase-style events',
            detail: 'Two events from one stream',
            buttonTitle: 'Send',
            action: () async {
              Flocon.analytics.sender('firebase').logEvents([
                const AnalyticsEvent(eventName: 'screen_view', properties: [AnalyticsProperty('screen_name', 'AnalyticsScreen'), AnalyticsProperty('screen_class', 'Flutter')]),
                const AnalyticsEvent(eventName: 'add_to_cart', properties: [AnalyticsProperty('item_id', 'sku_42'), AnalyticsProperty('value', '9.99'), AnalyticsProperty('currency', 'EUR')]),
              ]);
              return null;
            },
          ),
          SampleActionRow(
            title: 'Amplitude purchase',
            detail: 'A second provider, a second table',
            buttonTitle: 'Send',
            action: () async {
              Flocon.analytics.sender('amplitude').logEvents([
                const AnalyticsEvent(eventName: 'purchase', properties: [AnalyticsProperty('sku', 'pro_monthly'), AnalyticsProperty('price', '9.99')]),
              ]);
              return null;
            },
          ),
        ]),
        const SampleInfoCard('Each stream is its own table in Flocon > Analytics: use one stream per analytics provider.', tint: SampleTheme.accent),
      ]);
}
