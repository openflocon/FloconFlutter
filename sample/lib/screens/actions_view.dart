import 'package:flutter/material.dart';

/// A status line and a list of actions. Each action returns the status to display.
class SampleAction {
  const SampleAction(this.label, this.run);
  final String label;
  final Future<String> Function() run;
}

class ActionsView extends StatefulWidget {
  const ActionsView({super.key, required this.actions});
  final List<SampleAction> actions;

  @override
  State<ActionsView> createState() => _ActionsViewState();
}

class _ActionsViewState extends State<ActionsView> {
  String _status = 'Tap an action, then look at the Flocon desktop app';

  Future<void> _run(SampleAction action) async {
    setState(() => _status = '${action.label}…');
    String result;
    try {
      result = await action.run();
    } catch (e) {
      result = 'error: $e';
    }
    if (mounted) setState(() => _status = '${action.label} → $result');
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(_status)),
        Expanded(
          child: ListView(children: [
            for (final a in widget.actions)
              ListTile(title: Text(a.label), trailing: const Icon(Icons.play_arrow), onTap: () => _run(a)),
          ]),
        ),
      ]);
}
