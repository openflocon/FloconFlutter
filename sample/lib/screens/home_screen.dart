import 'package:flutter/material.dart';

import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';
import '../widgets/connection_chip.dart';
import '../widgets/sample_widgets.dart';

/// Lists the plugins: the four main ones as tiles, the others as rows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              const Expanded(
                child: Text(
                  'FLOCON SAMPLE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: SampleTheme.inkMuted),
                ),
              ),
              const SizedBox(width: 8),
              const ConnectionChip(),
            ]),
            const SizedBox(height: 12),
            const Text('Try every plugin,\none screen each', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 8),
            const Text('Trigger an action here, find it in Flocon Desktop.', style: TextStyle(color: SampleTheme.inkMuted)),
            const SizedBox(height: 24),
            GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 152,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final s in SampleScreen.main) _Tile(s)],
            ),
            const SizedBox(height: 24),
            SampleSection(title: 'More plugins', children: [for (final s in SampleScreen.others) _Row(s)]),
          ]),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.screen);
  final SampleScreen screen;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(screen.route),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SampleTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SampleTheme.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SampleCategoryIcon(icon: screen.icon, category: screen.category, size: 44),
            const Spacer(),
            Text(screen.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(screen.subtitle, style: const TextStyle(fontSize: 12, color: SampleTheme.inkMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.screen);
  final SampleScreen screen;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.of(context).pushNamed(screen.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            SampleCategoryIcon(icon: screen.icon, category: screen.category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(screen.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(screen.subtitle, style: const TextStyle(fontSize: 13, color: SampleTheme.inkMuted)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 20, color: SampleTheme.inkFaint),
          ]),
        ),
      );
}
