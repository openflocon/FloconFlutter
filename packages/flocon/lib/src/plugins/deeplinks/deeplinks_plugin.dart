import 'dart:convert';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// A value suggested for a deeplink parameter or variable.
class FloconDeeplinkSuggestion {
  const FloconDeeplinkSuggestion(this.value, {this.label, this.isDefault = false});

  /// What is inserted in the link when the suggestion is picked.
  final String value;

  /// What the desktop shows instead of [value].
  final String? label;

  /// Pre-selected by the desktop while the field is empty. Only the first default of a list is kept.
  final bool isDefault;

  Map<String, Object> toJson() => {
        'value': value,
        if (label != null) 'label': label!,
        if (isDefault) 'isDefault': true,
      };
}

/// Removes the duplicated values (the last declaration of a value wins) and keeps only the first default.
List<FloconDeeplinkSuggestion> normalizeDeeplinkSuggestions(List<FloconDeeplinkSuggestion> suggestions) {
  final lastIndex = <String, int>{};
  for (var i = 0; i < suggestions.length; i++) {
    lastIndex[suggestions[i].value] = i;
  }
  final unique = [
    for (var i = 0; i < suggestions.length; i++)
      if (lastIndex[suggestions[i].value] == i) suggestions[i],
  ];
  final defaultValue = unique.where((s) => s.isDefault).map((s) => s.value).firstOrNull;
  return [
    for (final s in unique)
      FloconDeeplinkSuggestion(s.value, label: s.label, isDefault: defaultValue != null && s.value == defaultValue),
  ];
}

/// A part of a deeplink the desktop lets you fill in: written between brackets in the link, for example `[userId]`.
sealed class FloconDeeplinkParameter {
  const FloconDeeplinkParameter(this.name);

  /// What is between the brackets.
  final String name;

  /// A parameter with suggestions.
  const factory FloconDeeplinkParameter.autoComplete(String name, List<String> suggestions) = FloconAutoCompleteParameter;

  /// A parameter with suggestions that can have a label, and a default one pre-selected by the desktop.
  const factory FloconDeeplinkParameter.suggestions(String name, List<FloconDeeplinkSuggestion> suggestions) = FloconSuggestionsParameter;

  /// A parameter shared by several deeplinks, edited once in the desktop (see [FloconDeeplinkVariable]).
  const factory FloconDeeplinkParameter.variable(String name, {required String variableName}) = FloconVariableParameter;

  Map<String, Object> toJson();
}

class FloconAutoCompleteParameter extends FloconDeeplinkParameter {
  const FloconAutoCompleteParameter(super.name, this.suggestions);
  final List<String> suggestions;

  @override
  Map<String, Object> toJson() => {'type': 'auto_complete', 'name': name, 'autoComplete': suggestions};
}

class FloconSuggestionsParameter extends FloconDeeplinkParameter {
  const FloconSuggestionsParameter(super.name, this.suggestions);
  final List<FloconDeeplinkSuggestion> suggestions;

  /// `autoComplete` keeps the values for desktops that do not know `suggestions` yet.
  @override
  Map<String, Object> toJson() {
    final items = normalizeDeeplinkSuggestions(suggestions);
    return {
      'type': 'auto_complete',
      'name': name,
      'autoComplete': [for (final s in items) s.value],
      'suggestions': [for (final s in items) s.toJson()],
    };
  }
}

class FloconVariableParameter extends FloconDeeplinkParameter {
  const FloconVariableParameter(super.name, {required this.variableName});
  final String variableName;

  @override
  Map<String, Object> toJson() => {'type': 'variable', 'name': name, 'variableName': variableName};
}

/// A deeplink of the app, listed in the Deeplinks section of the Flocon desktop app, which opens it.
class FloconDeeplink {
  const FloconDeeplink(this.link, {this.label, this.description, this.parameters = const []});

  /// The link, with the parts to fill in between brackets, for example `myapp://user/[userId]`.
  final String link;
  final String? label;
  final String? description;
  final List<FloconDeeplinkParameter> parameters;

  Map<String, Object> toJson() => {
        if (label != null) 'label': label!,
        'link': link,
        if (description != null) 'description': description!,
        'parameters': [for (final p in parameters) p.toJson()],
      };
}

/// A value shared by several deeplinks, edited once in the desktop app.
class FloconDeeplinkVariable {
  const FloconDeeplinkVariable(this.name, {this.description, this.suggestions, this.suggestionItems});

  final String name;
  final String? description;

  /// Plain values offered by the desktop. Ignored when [suggestionItems] is set.
  final List<String>? suggestions;

  /// Suggestions that can have a label, and a default one pre-selected by the desktop.
  final List<FloconDeeplinkSuggestion>? suggestionItems;

  Map<String, Object> toJson() {
    final items = suggestionItems == null ? null : normalizeDeeplinkSuggestions(suggestionItems!);
    return {
      'name': name,
      if (items != null)
        'mode': {
          'type': 'auto_complete',
          'suggestions': [for (final s in items) s.value],
          'items': [for (final s in items) s.toJson()],
        }
      else if (suggestions != null)
        'mode': {'type': 'auto_complete', 'suggestions': suggestions!},
      if (description != null) 'description': description!,
    };
  }
}

/// Lists the deeplinks of the app in the Flocon desktop app, replacing the previous list; it is sent again when the app
/// reconnects. The desktop opens them itself. Does nothing before `Flocon.initialize`.
///
/// ```dart
/// Flocon.deeplinks.register([
///   FloconDeeplink('myapp://home', label: 'Home'),
///   FloconDeeplink(
///     'myapp://user/[userId]',
///     label: 'User',
///     parameters: [FloconDeeplinkParameter.autoComplete('userId', ['Florent', 'David'])],
///   ),
///   FloconDeeplink('myapp://feed?tab=[tab]', parameters: [
///     FloconDeeplinkParameter.suggestions('tab', [
///       FloconDeeplinkSuggestion('posts', isDefault: true),
///       FloconDeeplinkSuggestion('friends', label: 'Friends list'),
///     ]),
///   ]),
///   FloconDeeplink('myapp://[env]/settings', parameters: [FloconDeeplinkParameter.variable('env', variableName: 'env')]),
/// ], variables: [FloconDeeplinkVariable('env', suggestions: ['staging', 'production'])]);
/// ```
class FloconDeeplinks {
  const FloconDeeplinks();

  void register(List<FloconDeeplink> deeplinks, {List<FloconDeeplinkVariable> variables = const []}) =>
      Flocon.deeplinksPlugin?.register(deeplinks, variables: variables);
}

/// Sends the deeplinks of the app to the Flocon desktop app.
class FloconDeeplinksPlugin implements FloconPlugin {
  FloconDeeplinksPlugin({required FloconMessageSender sender}) : _sender = sender;

  static const name = 'deeplink';
  static const methodGetDeeplinks = 'get_deeplinks';

  final FloconMessageSender _sender;
  String? _registered;

  @override
  String get pluginName => name;

  void register(List<FloconDeeplink> deeplinks, {List<FloconDeeplinkVariable> variables = const []}) {
    final body = jsonEncode({
      'deeplinks': [for (final d in deeplinks) d.toJson()],
      'variables': [for (final v in variables) v.toJson()],
    });
    _registered = body;
    _send(body);
  }

  @override
  void onConnectedToServer() {
    final body = _registered;
    if (body != null) _send(body);
  }

  /// The desktop app sends nothing to this plugin: it opens the deeplinks itself.
  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  void _send(String body) {
    try {
      _sender.send(plugin: pluginName, method: methodGetDeeplinks, body: body);
    } catch (_) {}
  }
}
