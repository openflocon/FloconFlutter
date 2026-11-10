import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// A key-value property attached to an [AnalyticsEvent].
class AnalyticsProperty {
  const AnalyticsProperty(this.name, this.value);
  final String name;
  final String value;
}

/// An analytics event, shown in the Analytics section of the Flocon desktop app.
class AnalyticsEvent {
  const AnalyticsEvent({required this.eventName, this.properties = const []});
  final String eventName;
  final List<AnalyticsProperty> properties;
}

/// Logs analytics events on a stream (one table per stream in the desktop app).
/// Use one stream per analytics provider.
///
/// ```dart
/// floconAnalytics('firebase').logEvents([
///   AnalyticsEvent(eventName: 'button_clicked', properties: [AnalyticsProperty('id', 'pay')]),
/// ]);
/// ```
class FloconAnalytics {
  const FloconAnalytics._(this.streamName);
  final String streamName;

  /// Does nothing before [Flocon.initialize].
  void logEvents(List<AnalyticsEvent> events) =>
      Flocon.analyticsPlugin?.registerAnalytics(streamName, events);
}

FloconAnalytics floconAnalytics(String streamName) =>
    FloconAnalytics._(streamName);

/// Sends analytics events to the Flocon desktop app.
class FloconAnalyticsPlugin implements FloconPlugin {
  FloconAnalyticsPlugin({required FloconMessageSender sender})
    : _sender = sender;

  static const name = 'analytics';
  static const methodAddItems = 'add_items';

  final FloconMessageSender _sender;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() {}

  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  /// Sends the events in a single message (the desktop expects a JSON array).
  void registerAnalytics(
    String streamName,
    List<AnalyticsEvent> events, {
    DateTime? createdAt,
  }) {
    if (events.isEmpty) return;
    final now = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    try {
      final body = jsonEncode([
        for (final e in events)
          {
            'id': const Uuid().v4(),
            'analytics_table_id': streamName,
            'event_name': e.eventName,
            'created_at': now,
            'properties': [
              for (final p in e.properties) {'name': p.name, 'value': p.value},
            ],
          },
      ]);
      _sender.send(plugin: pluginName, method: methodAddItems, body: body);
    } catch (_) {}
  }
}
