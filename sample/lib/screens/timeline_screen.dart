import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';
import '../widgets/sample_widgets.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _value = TextEditingController(text: 'tap_buy');
  final _paramKey = TextEditingController(text: 'sku');
  final _paramValue = TextEditingController(text: 'premium_yearly');
  final _tag = TextEditingController(text: 'billing');
  final _taggedValue = TextEditingController(text: 'Purchase failed');
  var _type = TimelineType.userAction;
  var _level = TimelineLevel.error;
  var _sent = 0;

  static const _types = [TimelineType.navigation, TimelineType.userAction, TimelineType.lifecycle];

  Map<String, String> get _params => {if (_paramKey.text.isNotEmpty) _paramKey.text: _paramValue.text};

  @override
  void dispose() {
    for (final c in [_value, _paramKey, _paramValue, _tag, _taggedValue]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _card(String title, List<Widget> children) => SampleSection(title: title, children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ]);

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.timeline, children: [
        _card('Typed logs (no level)', [
          SegmentedButton<TimelineType>(
            segments: [for (final t in _types) ButtonSegment(value: t, label: Text(t.name, style: const TextStyle(fontSize: 12)))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 10),
          SampleTextField(controller: _value, hint: 'Value'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SampleTextField(controller: _paramKey, hint: 'Param key')),
            const SizedBox(width: 10),
            Expanded(child: SampleTextField(controller: _paramValue, hint: 'Param value')),
          ]),
          const SizedBox(height: 12),
          SampleButton('Log', onPressed: () {
            floconTimeline.log(_type, _value.text, params: _params);
            setState(() => _sent++);
          }),
        ]),
        _card('Tagged log (with a level)', [
          SampleTextField(controller: _tag, hint: 'Tag'),
          const SizedBox(height: 10),
          SampleTextField(controller: _taggedValue, hint: 'Value'),
          const SizedBox(height: 10),
          SegmentedButton<TimelineLevel>(
            segments: [for (final l in TimelineLevel.values) ButtonSegment(value: l, label: Text(l.name, style: const TextStyle(fontSize: 12)))],
            selected: {_level},
            onSelectionChanged: (s) => setState(() => _level = s.first),
          ),
          const SizedBox(height: 12),
          SampleButton('Log', onPressed: () {
            floconTimeline.logTagged(_tag.text, _taggedValue.text, params: _params, level: _level);
            setState(() => _sent++);
          }),
        ]),
        SampleSection(title: 'Custom type', children: [
          SampleActionRow(
            title: 'TimelineType("billing")',
            detail: 'A custom type, sent without a level',
            buttonTitle: 'Log',
            action: () async {
              floconTimeline.log(const TimelineType('billing'), 'Purchase started', params: {'sku': 'premium_yearly'});
              setState(() => _sent++);
              return null;
            },
          ),
        ]),
        SampleInfoCard(
          'The screen changes of the sample and the app lifecycle are logged automatically. $_sent log(s) sent from this screen.',
          tint: SampleTheme.accent,
        ),
      ]);
}
