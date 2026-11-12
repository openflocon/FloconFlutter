import 'dart:convert';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// The type of a timeline event.
///
/// The reserved types are [navigation], [userAction] and [lifecycle]: the desktop shows them with their own icon.
/// Any other name is a custom type, for example `TimelineType('billing')`.
class TimelineType {
  const TimelineType(this.name);

  /// Name of the type, as sent to the desktop app.
  final String name;

  /// A screen change.
  static const navigation = TimelineType('navigation');

  /// An action of the user: a tap, a swipe, a form submission...
  static const userAction = TimelineType('userAction');

  /// A lifecycle event of the app or of a screen.
  static const lifecycle = TimelineType('lifecycle');

  @override
  bool operator ==(Object other) => other is TimelineType && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Severity of a tagged timeline event.
enum TimelineLevel { debug, info, warning, error }

/// Logs what happens in the app in the Flocon timeline: navigation, user actions, lifecycle and your own events.
///
/// ```dart
/// Flocon.timeline.logNavigation('CheckoutScreen', params: {'from': 'CartScreen'});
/// Flocon.timeline.logUserAction('tap_buy', params: {'sku': 'premium_yearly'});
/// Flocon.timeline.logTagged('billing', 'Purchase failed', level: TimelineLevel.error);
/// ```
///
/// There are two kinds of calls, never mixed: the typed ones have no level, the tagged one always has one. Params are
/// text only. The calls do nothing before `Flocon.initialize`.
class FloconTimeline {
  const FloconTimeline();

  /// Logs an event of the given type, without any level.
  void log(TimelineType type, String value, {Map<String, String> params = const {}}) =>
      Flocon.timelinePlugin?.send(type: type.name, value: value, params: params);

  /// Logs a custom event: [tag] is its type, for example `'billing'`, with a [level].
  void logTagged(
    String tag,
    String value, {
    Map<String, String> params = const {},
    TimelineLevel level = TimelineLevel.info,
  }) =>
      Flocon.timelinePlugin?.send(type: tag, value: value, params: params, level: level);

  /// Logs a screen change.
  void logNavigation(String value, {Map<String, String> params = const {}}) =>
      log(TimelineType.navigation, value, params: params);

  /// Logs an action of the user.
  void logUserAction(String value, {Map<String, String> params = const {}}) =>
      log(TimelineType.userAction, value, params: params);

  /// Logs a lifecycle event.
  void logLifecycle(String value, {Map<String, String> params = const {}}) =>
      log(TimelineType.lifecycle, value, params: params);
}

/// Sends the timeline events to the Flocon desktop app.
class FloconTimelinePlugin implements FloconPlugin {
  FloconTimelinePlugin({required FloconMessageSender sender, DateTime Function()? now})
      : _sender = sender,
        _now = now ?? DateTime.now;

  static const name = 'timeline';
  static const methodLog = 'log';

  final FloconMessageSender _sender;
  final DateTime Function() _now;

  @override
  String get pluginName => name;

  /// Nothing is kept: the events are sent when they are logged, then kept by the SDK until a desktop is reachable.
  @override
  void onConnectedToServer() {}

  /// The desktop app is read only: it sends nothing to this plugin.
  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  /// The timestamp is the moment of the call, not the moment the message is sent.
  void send({
    required String type,
    required String value,
    Map<String, String> params = const {},
    TimelineLevel? level,
  }) {
    final timestamp = _now().millisecondsSinceEpoch;
    try {
      _sender.send(
        plugin: pluginName,
        method: methodLog,
        body: jsonEncode({
          'type': type,
          'value': value,
          if (params.isNotEmpty) 'params': params,
          if (level != null) 'level': level.name,
          'timestamp': timestamp,
        }),
      );
    } catch (_) {}
  }
}
