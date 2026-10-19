import 'dart:convert';
import 'dart:io';

import 'crash_report.dart';

/// Keeps the crashes on disk until they are sent to the desktop app. Each crash is a JSON file.
///
/// Writes are synchronous: the app may be about to die.
class FloconCrashStore {
  FloconCrashStore(this.directory);

  final Directory directory;

  void save(FloconCrashReport report) {
    try {
      directory.createSync(recursive: true);
      File('${directory.path}/${report.crashId}.json').writeAsStringSync(jsonEncode(report.toJson()), flush: true);
    } catch (_) {
      // nothing more can be done while crashing
    }
  }

  /// The crashes not sent yet, oldest first. Unreadable files are skipped.
  List<FloconCrashReport> pendingReports() {
    if (!directory.existsSync()) return [];
    final reports = <FloconCrashReport>[];
    for (final entity in directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        reports.add(FloconCrashReport.fromJson(jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>));
      } catch (_) {}
    }
    return reports..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void delete(FloconCrashReport report) {
    try {
      File('${directory.path}/${report.crashId}.json').deleteSync();
    } catch (_) {}
  }
}
