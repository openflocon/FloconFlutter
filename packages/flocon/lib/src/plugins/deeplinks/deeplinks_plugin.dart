import 'dart:convert';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// A part of a deeplink the desktop lets you fill in: written between brackets in the link, for example `[userId]`.
sealed class FloconDeeplinkParameter {
  const FloconDeeplinkParameter(this.name);

  /// What is between the brackets.
  final String name;

  /// A parameter with suggestions.
  const factory FloconDeeplinkParameter.autoComplete(String name, List<String> suggestions) = FloconAutoCompleteParameter;

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
  const FloconDeeplinkVariable(this.name, {this.description, this.suggestions});

  final String name;
  final String? description;
  final List<String>? suggestions;

  Map<String, Object> toJson() => {
        'name': name,
        if (suggestions != null) 'mode': {'type': 'auto_complete', 'suggestions': suggestions!},
        if (description != null) 'description': description!,
      };
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
