import 'package:flutter/material.dart';

import '../startup/sample_state.dart';
import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

class FeatureFlagsScreen extends StatelessWidget {
  const FeatureFlagsScreen({super.key});

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.featureFlags, children: [
        SampleSection(title: 'Flags', children: [
          SampleActionRow(
            title: 'Register flags',
            detail: 'Firebase and Statsig flags, with variants and payloads',
            buttonTitle: 'Register',
            action: () async {
              SampleStartup.registerFeatureFlags();
              return '5 flags, 2 providers';
            },
          ),
          SampleActionRow(
            title: 'Shuffle variants',
            detail: 'Registers them again with other variants',
            buttonTitle: 'Shuffle',
            action: () async {
              SampleStartup.registerFeatureFlags(shuffled: true);
              return 'registered again';
            },
          ),
        ]),
        const SampleInfoCard(
          'Flags are registered when the app starts, and again on each connection. Open Flocon > Feature flags: click a flag to see its payload, '
          'then shuffle the variants here and watch them change.',
        ),
      ]);
}
