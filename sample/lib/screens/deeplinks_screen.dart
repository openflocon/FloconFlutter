import 'package:flutter/material.dart';

import '../startup/sample_state.dart';
import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

/// The deeplinks are listed in Flocon > Deeplinks, with their parameters. Here they open inside the sample.
class DeeplinksScreen extends StatelessWidget {
  const DeeplinksScreen({super.key});

  Widget _link(String url, String detail) => SampleActionRow(
        title: url,
        detail: detail,
        buttonTitle: 'Open',
        action: () async => SampleDeeplinks.open(url) ? null : throw 'Not a deeplink of the sample',
      );

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.deeplinks, children: [
        SampleSection(title: 'Open from the app', children: [
          _link('flocondemo://home', 'Back to the home'),
          _link('flocondemo://user/Florent', 'Profile of a user'),
          _link('flocondemo://post/2?comment=Nice', 'A post with a prefilled comment'),
          _link('flocondemo://staging/settings', 'Settings of an environment'),
        ]),
        const SampleInfoCard(
          'The same links are listed in Flocon > Deeplinks, with their parameters and the shared "env" variable. '
          'On the iOS Simulator: xcrun simctl openurl booted "flocondemo://user/Florent" (the sample registers no URL scheme: the desktop opens the links '
          'of an app that does).',
        ),
      ]);
}

/// A destination of a deeplink.
class DeeplinkDestinationScreen extends StatelessWidget {
  const DeeplinkDestinationScreen({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            SampleSection(title: title, children: [
              for (final line in lines) Padding(padding: const EdgeInsets.all(16), child: Text(line)),
            ]),
          ]),
        ),
      );
}
