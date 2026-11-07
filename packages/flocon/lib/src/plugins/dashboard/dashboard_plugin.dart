import 'dart:async';
import 'dart:convert';

import '../../core/logger.dart';
import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';
import 'dashboard_content.dart';
import 'dashboard_elements.dart';

/// Stops a dashboard from following its reactive sections. The dashboard stays in the desktop, as last sent.
class FloconDashboardHandle {
  FloconDashboardHandle(this._subscriptions);

  final List<StreamSubscription<FloconContainer>> _subscriptions;

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}

/// Shows values of the app in the Flocon desktop app, and runs actions in it from there.
///
/// A section is either static, or rebuilt each time a `ValueListenable` or a `Stream` emits. Keep the handle: the
/// dashboard stops following them when you call `dispose`. The dashboard is sent once every reactive section has a
/// value, and again on each connection. Does nothing before `Flocon.initialize`.
///
/// ```dart
/// final handle = floconDashboard('main', [
///   FloconSection.listen('User', session.user, (user) => [
///     FloconText('name', user.name),
///     FloconButton('Log out', id: 'logout', onClick: session.logOut),
///     FloconTextField(id: 'rename', label: 'Rename', value: user.name, onSubmitted: session.rename),
///     FloconCheckBox(id: 'premium', label: 'Premium', value: user.isPremium, onChanged: session.setPremium),
///   ]),
///   FloconSection('Build', [FloconPlainText('commit', buildCommit), FloconJson('config', configJson)]),
///   FloconForm('Create user', [
///     FloconTextField(id: 'name', label: 'Name', value: ''),
///     FloconCheckBox(id: 'admin', label: 'Admin', value: false),
///   ], submitText: 'Create', onSubmitted: (values) => session.createUser(values['name']!, values['admin'] == 'true')),
/// ]);
/// ```
FloconDashboardHandle floconDashboard(
  String id,
  List<FloconDashboardContent> contents,
) =>
    Flocon.dashboardPlugin?.dashboard(id, contents) ??
    FloconDashboardHandle([]);

/// Sends the dashboards of the app to the Flocon desktop app, and routes the actions made there.
class FloconDashboardPlugin implements FloconPlugin {
  FloconDashboardPlugin({required FloconMessageSender sender})
    : _sender = sender;

  static const name = 'dashboard';
  static const methodUpdate = 'update';
  static const methodOnClick = 'on_click';
  static const methodOnFormSubmitted = 'on_form_submitted';
  static const methodOnTextFieldSubmitted = 'on_text_field_submitted';
  static const methodOnCheckBoxValueChanged = 'on_check_box_value_changed';

  final FloconMessageSender _sender;
  final _dashboards = <String, _Dashboard>{};

  @override
  String get pluginName => name;

  /// Starts a dashboard: it is sent once all its blocks have a value.
  FloconDashboardHandle dashboard(
    String id,
    List<FloconDashboardContent> contents,
  ) {
    if (contents.isEmpty) {
      _register(id, const []);
      return FloconDashboardHandle([]);
    }
    final latest = List<FloconContainer?>.filled(contents.length, null);
    final subscriptions = <StreamSubscription<FloconContainer>>[];
    for (var i = 0; i < contents.length; i++) {
      subscriptions.add(
        contents[i].containers().listen((container) {
          latest[i] = container;
          if (latest.every((c) => c != null)) {
            _register(id, latest.cast<FloconContainer>());
          }
        }),
      );
    }
    return FloconDashboardHandle(subscriptions);
  }

  void _register(String id, List<FloconContainer> containers) {
    final dashboard = _Dashboard(id, List.of(containers));
    _dashboards[id] = dashboard;
    _send(dashboard);
  }

  @override
  void onConnectedToServer() {
    for (final dashboard in _dashboards.values.toList()) {
      _send(dashboard);
    }
  }

  @override
  void onMessageReceived(FloconMessageFromServer message) {
    try {
      switch (message.method) {
        case methodOnClick:
          // the body is the identifier of the button
          final id = _unquote(message.body);
          _callback(id)?.onClick?.call();
        case methodOnTextFieldSubmitted:
          final event = jsonDecode(message.body) as Map<String, dynamic>;
          _callback(event['id'] as String)?.onTextFieldSubmitted?.call(
            event['value'] as String,
          );
        case methodOnCheckBoxValueChanged:
          final event = jsonDecode(message.body) as Map<String, dynamic>;
          _callback(event['id'] as String)?.onCheckBoxChanged?.call(
            event['value'] as bool,
          );
        case methodOnFormSubmitted:
          final event = jsonDecode(message.body) as Map<String, dynamic>;
          final callback = _callback(event['id'] as String);
          final form = callback?.form;
          if (form == null) return;
          // gives back the identifiers of the app: "<dashboardId>_name" -> "name"
          final prefix = '${callback!.dashboardId}_';
          final values = {
            for (final entry in (event['values'] as Map<String, dynamic>).entries)
              (entry.key.startsWith(prefix)
                  ? entry.key.substring(prefix.length)
                  : entry.key): '${entry.value}',
          };
          form(values);
        default:
          FloconLogger.log('Unknown dashboard method: ${message.method}');
      }
    } catch (e) {
      FloconLogger.logError('Dashboard message error', e);
    }
  }

  static String _unquote(String body) {
    final text = body.trim();
    if (text.startsWith('"')) {
      try {
        return jsonDecode(text) as String;
      } catch (_) {}
    }
    return text;
  }

  _Callback? _callback(String actionId) {
    for (final dashboard in _dashboards.values) {
      final callback = dashboard.callbacks[actionId];
      if (callback != null) return callback;
    }
    return null;
  }

  void _send(_Dashboard dashboard) {
    try {
      _sender.send(
        plugin: pluginName,
        method: methodUpdate,
        body: jsonEncode(dashboard.toJson()),
      );
    } catch (_) {}
  }
}

class _Callback {
  _Callback(this.dashboardId);

  final String dashboardId;
  void Function()? onClick;
  void Function(String)? onTextFieldSubmitted;
  void Function(bool)? onCheckBoxChanged;
  void Function(Map<String, String>)? form;
}

/// A dashboard as sent to the desktop, with the callbacks of its actions.
class _Dashboard {
  _Dashboard(this.id, this.containers) {
    json = {
      'dashboardId': id,
      'containers': [for (final c in containers) _container(c)],
    };
  }

  final String id;
  final List<FloconContainer> containers;
  final callbacks = <String, _Callback>{};
  late final Map<String, Object> json;

  Map<String, Object> toJson() => json;

  String _actionId(String elementId) => '${id}_$elementId';

  Map<String, Object> _container(FloconContainer container) {
    var config = <String, Object>{'containerType': 'SECTION'};
    if (container.isForm) {
      final formId = _actionId('form_${container.name}');
      callbacks[formId] = _Callback(id)..form = container.onSubmitted;
      config = {
        'containerType': 'FORM',
        'formId': formId,
        'submitText': container.submitText!,
      };
    }
    return {
      'name': container.name,
      'elements': [for (final e in container.elements) _element(e)],
      'containerConfig': config,
    };
  }

  // the color is an ARGB Int32 on the wire
  static int? _color(int? color) => color?.toSigned(32);

  Map<String, Object> _element(FloconDashboardElement element) {
    switch (element) {
      case FloconText():
        return {
          'text': {
            'label': element.label,
            'value': element.value,
            if (element.color != null) 'color': _color(element.color)!,
          },
        };
      case FloconLabel():
        return {
          'label': {
            'label': element.label,
            if (element.color != null) 'color': _color(element.color)!,
          },
        };
      case FloconPlainText():
        return {
          'plainText': {
            'label': element.label,
            'value': element.value,
            'type': 'text',
          },
        };
      case FloconJson():
        return {
          'plainText': {
            'label': element.label,
            'value': element.value,
            'type': 'json',
          },
        };
      case FloconMarkdown():
        return {
          'markdown': {'label': element.label, 'value': element.value},
        };
      case FloconHtml():
        return {
          'html': {'label': element.label, 'value': element.value},
        };
      case FloconButton():
        final actionId = _actionId(element.id);
        callbacks[actionId] = _Callback(id)..onClick = element.onClick;
        return {
          'button': {'id': actionId, 'text': element.text},
        };
      case FloconTextField():
        final actionId = _actionId(element.id);
        callbacks[actionId] = _Callback(id)
          ..onTextFieldSubmitted = element.onSubmitted;
        return {
          'textField': {
            'id': actionId,
            'label': element.label,
            if (element.placeholder != null) 'placeHolder': element.placeholder!,
            'value': element.value,
          },
        };
      case FloconCheckBox():
        final actionId = _actionId(element.id);
        callbacks[actionId] = _Callback(id)
          ..onCheckBoxChanged = element.onChanged;
        return {
          'checkBox': {
            'id': actionId,
            'label': element.label,
            'value': element.value,
          },
        };
    }
  }
}
