import 'package:flutter/foundation.dart';

/// An element of a dashboard section or form. Identifiers (`id`) must be unique in their dashboard.
sealed class FloconDashboardElement {
  const FloconDashboardElement();
}

/// A label with a value, optionally colored (`0xAARRGGBB`).
class FloconText extends FloconDashboardElement {
  const FloconText(this.label, this.value, {this.color});
  final String label;
  final String value;
  final int? color;
}

/// A label alone.
class FloconLabel extends FloconDashboardElement {
  const FloconLabel(this.label, {this.color});
  final String label;
  final int? color;
}

/// A text shown as it is, selectable.
class FloconPlainText extends FloconDashboardElement {
  const FloconPlainText(this.label, this.value);
  final String label;
  final String value;
}

/// A JSON text, shown formatted.
class FloconJson extends FloconDashboardElement {
  const FloconJson(this.label, this.value);
  final String label;
  final String value;
}

class FloconMarkdown extends FloconDashboardElement {
  const FloconMarkdown(this.label, this.value);
  final String label;
  final String value;
}

class FloconHtml extends FloconDashboardElement {
  const FloconHtml(this.label, this.value);
  final String label;
  final String value;
}

/// A button that runs [onClick] in the app.
class FloconButton extends FloconDashboardElement {
  const FloconButton(this.text, {required this.id, required this.onClick});
  final String text;
  final String id;
  final VoidCallback onClick;
}

/// An input whose value is sent to [onSubmitted] when it is submitted in the desktop.
class FloconTextField extends FloconDashboardElement {
  const FloconTextField({
    required this.id,
    required this.label,
    required this.value,
    this.placeholder,
    this.onSubmitted,
  });
  final String id;
  final String label;
  final String value;
  final String? placeholder;
  final ValueChanged<String>? onSubmitted;
}

/// A check box whose changes in the desktop are sent to [onChanged].
class FloconCheckBox extends FloconDashboardElement {
  const FloconCheckBox({
    required this.id,
    required this.label,
    required this.value,
    this.onChanged,
  });
  final String id;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
}
