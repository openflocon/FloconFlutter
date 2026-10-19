import 'package:flutter/material.dart';

/// Errors reported to the Crash reporter section of Flocon. The app keeps running: Flutter
/// catches these errors and hands them to the handlers installed by `floconEnableCrashReporter`.
class CrashScreen extends StatelessWidget {
  const CrashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crash reporter')),
        body: ListView(children: [
          ListTile(
            title: const Text('Throw in a gesture callback'),
            subtitle: const Text('Reported through FlutterError.onError'),
            trailing: const Icon(Icons.warning_amber),
            onTap: () => throw StateError('Sample error thrown from a tap handler'),
          ),
          ListTile(
            title: const Text('Unhandled async error'),
            subtitle: const Text('Reported through PlatformDispatcher.onError'),
            trailing: const Icon(Icons.warning_amber),
            onTap: () => Future<void>.delayed(
              const Duration(milliseconds: 100),
              () => throw ArgumentError('Sample unhandled error from a Future'),
            ),
          ),
          ListTile(
            title: const Text('Error while building a widget'),
            subtitle: const Text('Shows the red error screen on the next screen'),
            trailing: const Icon(Icons.warning_amber),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _BrokenScreen())),
          ),
        ]),
      );
}

class _BrokenScreen extends StatelessWidget {
  const _BrokenScreen();

  @override
  Widget build(BuildContext context) => throw UnsupportedError('Sample error thrown in build()');
}
