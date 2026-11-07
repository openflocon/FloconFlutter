import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import '../theme/sample_theme.dart';

Color connectionColor(FloconConnectionState state) => switch (state) {
      FloconConnected() => SampleTheme.success,
      FloconConnecting() => SampleTheme.warning,
      FloconFailed() => SampleTheme.error,
      FloconIdle() || FloconBuffering() => SampleTheme.inkFaint,
    };

String connectionLabel(FloconConnectionState state) => switch (state) {
      FloconIdle() => 'Flocon is not started',
      FloconBuffering() => 'Not connected, messages are kept',
      FloconConnecting() => 'Connecting…',
      FloconConnected() => 'Connected to Flocon Desktop',
      FloconFailed(:final reason) => 'Failed: $reason',
    };

/// The button of the home, next to the title: the dot shows the state of the connection.
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<FloconConnectionState>(
        stream: Flocon.connectionStates,
        initialData: Flocon.connectionState,
        builder: (context, snapshot) => InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Navigator.of(context).pushNamed('/connection'),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SampleTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: SampleTheme.line),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi, size: 14),
              const SizedBox(width: 6),
              const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: connectionColor(snapshot.data ?? const FloconIdle())),
              ),
            ]),
          ),
        ),
      );
}
