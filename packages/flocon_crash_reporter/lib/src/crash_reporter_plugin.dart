import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:uuid/uuid.dart';

import 'crash_report.dart';
import 'crash_store.dart';

/// Reports the crashes of the app to the Flocon desktop app.
///
/// Every crash is first saved on disk, as the app may not survive it. It is sent right away when the
/// desktop is connected, otherwise on the next connection (even after a restart), then deleted.
class FloconCrashReporterPlugin implements FloconPlugin {
  FloconCrashReporterPlugin({
    required FloconMessageSender sender,
    required FloconCrashStore store,
    bool Function()? isConnected,
  })  : _sender = sender,
        _store = store,
        _isConnected = isConnected ?? (() => Flocon.isConnected);

  static const name = 'crash_reporter';
  static const methodReportCrash = 'report_crash';

  final FloconMessageSender _sender;
  final FloconCrashStore _store;
  final bool Function() _isConnected;

  @override
  String get pluginName => name;

  @override
  void onConnectedToServer() => sendPendingCrashes();

  /// The desktop sends nothing to this plugin.
  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  /// Saves an error, and sends it right away when connected. Never throws.
  void recordError(Object error, StackTrace? stack) {
    try {
      _store.save(FloconCrashReport(
        crashId: const Uuid().v4(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        exceptionType: error.runtimeType.toString(),
        exceptionMessage: error.toString(),
        stackTrace: (stack ?? StackTrace.current).toString(),
      ));
      if (_isConnected()) sendPendingCrashes();
    } catch (_) {}
  }

  /// Sends the saved crashes in a single message (a JSON array), then deletes them.
  void sendPendingCrashes() {
    try {
      final reports = _store.pendingReports();
      if (reports.isEmpty) return;
      _sender.send(
        plugin: pluginName,
        method: methodReportCrash,
        body: jsonEncode([for (final r in reports) r.toJson()]),
      );
      // the client keeps the message in order and queues it while disconnected
      reports.forEach(_store.delete);
    } catch (_) {}
  }
}
