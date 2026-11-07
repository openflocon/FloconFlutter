import 'package:flutter/material.dart';

import '../theme/sample_screen.dart';
import '../theme/sample_theme.dart';

/// The frame shared by every plugin screen: dark background, the icon and subtitle of the plugin, then the content.
class SampleScreenContainer extends StatelessWidget {
  const SampleScreenContainer({super.key, required this.screen, required this.children});

  final SampleScreen screen;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(screen.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                SampleCategoryIcon(icon: screen.icon, category: screen.category, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Text(screen.subtitle, style: const TextStyle(color: SampleTheme.inkMuted))),
              ]),
              const SizedBox(height: 10),
              const SamplePlatformChips(),
              const SizedBox(height: 20),
              for (final child in children) ...[child, const SizedBox(height: 20)],
            ],
          ),
        ),
      );
}

class SampleCategoryIcon extends StatelessWidget {
  const SampleCategoryIcon({super.key, required this.icon, required this.category, this.size = 36});

  final IconData icon;
  final SampleCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: category.soft, borderRadius: BorderRadius.circular(size / 3.5)),
        child: Icon(icon, size: size * 0.5, color: category.color),
      );
}

/// Where the feature works.
class SamplePlatformChips extends StatelessWidget {
  const SamplePlatformChips({super.key, this.platforms = const ['Android', 'iOS', 'macOS']});

  final List<String> platforms;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final p in platforms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: SampleTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SampleTheme.line),
            ),
            child: Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SampleTheme.inkMuted)),
          ),
      ]);
}

/// A card with a divider between its rows.
class SampleCard extends StatelessWidget {
  const SampleCard({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: SampleTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SampleTheme.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(),
              children[i],
            ],
          ]),
        ),
      );
}

/// A titled card of rows.
class SampleSection extends StatelessWidget {
  const SampleSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: SampleTheme.inkFaint),
          ),
        ),
        const SizedBox(height: 8),
        SampleCard(children: children),
      ]);
}

class SampleButton extends StatelessWidget {
  const SampleButton(this.label, {super.key, required this.onPressed, this.isDestructive = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: isDestructive ? SampleTheme.error.withValues(alpha: 0.85) : SampleTheme.accent,
      foregroundColor: isDestructive ? SampleTheme.ink : SampleTheme.onAccent,
      disabledBackgroundColor: SampleTheme.surfaceHighest,
      disabledForegroundColor: SampleTheme.inkFaint,
      minimumSize: const Size(60, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 18), label: Text(label));
  }
}

/// One feature of the SDK: a title, what it does, a button, and the result (duration or error) of the last run.
class SampleActionRow extends StatefulWidget {
  const SampleActionRow({
    super.key,
    required this.title,
    required this.detail,
    required this.action,
    this.buttonTitle = 'Run',
    this.isDestructive = false,
  });

  final String title;
  final String detail;
  final String buttonTitle;
  final bool isDestructive;

  /// Returns a short result to show next to the duration, or null.
  final Future<String?> Function() action;

  @override
  State<SampleActionRow> createState() => _SampleActionRowState();
}

sealed class _Outcome {
  const _Outcome();
}

class _Idle extends _Outcome {
  const _Idle();
}

class _Running extends _Outcome {
  const _Running();
}

class _Success extends _Outcome {
  const _Success(this.result, this.millis);
  final String? result;
  final int millis;
}

class _Failure extends _Outcome {
  const _Failure(this.message);
  final String message;
}

class _SampleActionRowState extends State<SampleActionRow> {
  _Outcome _outcome = const _Idle();

  Future<void> _run() async {
    setState(() => _outcome = const _Running());
    final stopwatch = Stopwatch()..start();
    _Outcome next;
    try {
      next = _Success(await widget.action(), stopwatch.elapsedMilliseconds);
    } catch (e) {
      next = _Failure('$e');
    }
    if (mounted) setState(() => _outcome = next);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(widget.detail, style: const TextStyle(fontSize: 13, color: SampleTheme.inkMuted)),
              switch (_outcome) {
                _Idle() => const SizedBox.shrink(),
                _Running() => const _Note('Running…', SampleTheme.inkMuted),
                _Success(:final result, :final millis) =>
                  _Note('✓ ${[?result, '$millis ms'].join(' · ')}', SampleTheme.success),
                _Failure(:final message) => _Note('✕ $message', SampleTheme.error),
              },
            ]),
          ),
          const SizedBox(width: 12),
          SampleButton(
            widget.buttonTitle,
            isDestructive: widget.isDestructive,
            onPressed: _outcome is _Running ? null : _run,
          ),
        ]),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: TextStyle(fontSize: 13, color: color), maxLines: 4, overflow: TextOverflow.ellipsis),
      );
}

/// A small tinted note: tips, how to trigger something from the outside.
class SampleInfoCard extends StatelessWidget {
  const SampleInfoCard(this.text, {super.key, this.tint = SampleTheme.warning});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.33)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      );
}

/// A labelled text input, in the style of the sample.
class SampleTextField extends StatelessWidget {
  const SampleTextField({super.key, required this.controller, required this.hint, this.onSubmitted});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: onSubmitted,
      );
}
