import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dashboard_elements.dart';

/// A block of a dashboard: a section or a form, with its elements. Sections can follow a stream or a
/// `ValueListenable`: they are rebuilt, and the dashboard sent again, each time it emits.
sealed class FloconDashboardContent {
  const FloconDashboardContent();

  /// The block to show, each time it changes.
  Stream<FloconContainer> containers();
}

/// A block with its elements, ready to be sent.
class FloconContainer {
  const FloconContainer.section(this.name, this.elements)
    : submitText = null,
      onSubmitted = null;
  const FloconContainer.form(
    this.name,
    this.elements, {
    required String this.submitText,
    required void Function(Map<String, String> values) this.onSubmitted,
  });

  final String name;
  final List<FloconDashboardElement> elements;
  final String? submitText;
  final void Function(Map<String, String> values)? onSubmitted;

  bool get isForm => onSubmitted != null;
}

/// A titled group of elements.
class FloconSection extends FloconDashboardContent {
  const FloconSection(this.name, [this.elements = const []]);

  /// A section rebuilt each time [valueListenable] changes (a `ValueNotifier`, a `ChangeNotifier`...).
  ///
  /// ```dart
  /// FloconSection.listen('User', session.user, (user) => [FloconText('name', user.name)])
  /// ```
  static FloconDashboardContent listen<T>(
    String name,
    ValueListenable<T> valueListenable,
    List<FloconDashboardElement> Function(T value) builder,
  ) => _ListenableSection<T>(name, valueListenable, builder);

  /// A section rebuilt each time [stream] emits. Nothing is sent until its first value.
  static FloconDashboardContent fromStream<T>(
    String name,
    Stream<T> stream,
    List<FloconDashboardElement> Function(T value) builder,
  ) => _StreamSection<T>(name, stream, builder);

  final String name;
  final List<FloconDashboardElement> elements;

  @override
  Stream<FloconContainer> containers() =>
      Stream.value(FloconContainer.section(name, elements));
}

class _ListenableSection<T> extends FloconDashboardContent {
  _ListenableSection(this.name, this.listenable, this.builder);

  final String name;
  final ValueListenable<T> listenable;
  final List<FloconDashboardElement> Function(T value) builder;

  @override
  Stream<FloconContainer> containers() {
    late StreamController<FloconContainer> controller;
    void emit() =>
        controller.add(FloconContainer.section(name, builder(listenable.value)));
    controller = StreamController<FloconContainer>(
      onListen: () {
        listenable.addListener(emit);
        emit();
      },
      onCancel: () => listenable.removeListener(emit),
    );
    return controller.stream;
  }
}

class _StreamSection<T> extends FloconDashboardContent {
  _StreamSection(this.name, this.stream, this.builder);

  final String name;
  final Stream<T> stream;
  final List<FloconDashboardElement> Function(T value) builder;

  @override
  Stream<FloconContainer> containers() =>
      stream.map((value) => FloconContainer.section(name, builder(value)));
}

/// A group of inputs sent together: [onSubmitted] gets their values, keyed by their ids, with check boxes as
/// `'true'` or `'false'`.
class FloconForm extends FloconDashboardContent {
  const FloconForm(
    this.name,
    this.elements, {
    required this.submitText,
    required this.onSubmitted,
  });

  final String name;
  final List<FloconDashboardElement> elements;
  final String submitText;
  final void Function(Map<String, String> values) onSubmitted;

  @override
  Stream<FloconContainer> containers() => Stream.value(
    FloconContainer.form(
      name,
      elements,
      submitText: submitText,
      onSubmitted: onSubmitted,
    ),
  );
}
