import 'package:flutter/material.dart';

import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

/// Errors reported to Flocon > Crashes. The app keeps running: Flutter catches them and hands them to the handlers
/// installed by `floconEnableCrashReporter`, which sends them right away.
class CrashScreen extends StatelessWidget {
  const CrashScreen({super.key});

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.crash, children: [
        SampleSection(title: 'Errors', children: [
          SampleActionRow(
            title: 'Error in a gesture callback',
            detail: 'Reported through FlutterError.onError',
            buttonTitle: 'Throw',
            isDestructive: true,
            // a callback error is caught by the framework (the tap handler), so it goes to FlutterError.onError
            action: () async {
              Future<void>.microtask(() => FlutterError.reportError(FlutterErrorDetails(
                    exception: StateError('Sample error from a gesture callback'),
                    stack: StackTrace.current,
                    library: 'flocon sample',
                    context: ErrorDescription('while handling a gesture'),
                  )));
              return 'reported';
            },
          ),
          SampleActionRow(
            title: 'Unhandled async error',
            detail: 'Reported through PlatformDispatcher.onError',
            buttonTitle: 'Throw',
            isDestructive: true,
            action: () async {
              Future<void>.delayed(const Duration(milliseconds: 100), () => throw ArgumentError('Sample unhandled error from a Future'));
              return 'thrown in a Future';
            },
          ),
          SampleActionRow(
            title: 'Error while building a widget',
            detail: 'Shows the red error screen on the next screen',
            buttonTitle: 'Open',
            isDestructive: true,
            action: () async {
              Navigator.of(context).push(MaterialPageRoute<void>(settings: const RouteSettings(name: '/broken'), builder: (_) => const _BrokenScreen()));
              return null;
            },
          ),
        ]),
        const SampleInfoCard('Each error shows up in Flocon > Crashes with its stack trace. Native crashes (Kotlin, Swift) are not reported.'),
      ]);
}

class _BrokenScreen extends StatelessWidget {
  const _BrokenScreen();

  @override
  Widget build(BuildContext context) => throw UnsupportedError('Sample error thrown in build()');
}
