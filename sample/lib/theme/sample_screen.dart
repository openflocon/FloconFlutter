import 'package:flutter/material.dart';

import 'sample_theme.dart';

/// One screen per plugin of the SDK.
enum SampleScreen {
  network('Network', 'HTTP (Dio, http), WebSocket, mocks', Icons.swap_vert, SampleCategory.network),
  database('Database', 'SQLite queries', Icons.storage_outlined, SampleCategory.database),
  analytics('Analytics', 'Events and properties', Icons.bar_chart, SampleCategory.analytics),
  featureFlags('Feature flags', 'Register and observe', Icons.flag_outlined, SampleCategory.featureFlags),
  preferences('Preferences', 'SharedPreferences', Icons.table_chart_outlined, SampleCategory.neutral),
  files('Files', 'Files the desktop can browse', Icons.folder_outlined, SampleCategory.neutral),
  dashboard('Dashboard & Tables', 'Live values and table rows', Icons.view_agenda_outlined, SampleCategory.table),
  deeplinks('Deeplinks', 'Links listed in the desktop', Icons.link, SampleCategory.deeplink),
  timeline('Timeline', 'Navigation, actions and tagged logs', Icons.schedule, SampleCategory.timeline),
  images('Images', 'Images loaded over HTTP', Icons.photo_outlined, SampleCategory.neutral),
  crash('Crash reporter', 'Throw errors on purpose', Icons.warning_amber, SampleCategory.crash);

  const SampleScreen(this.title, this.subtitle, this.icon, this.category);

  final String title;
  final String subtitle;
  final IconData icon;
  final SampleCategory category;

  String get route => '/$name';

  /// The four plugins shown as tiles on the home, the others are listed under them.
  static const main = [network, database, analytics, featureFlags];
  static final others = [for (final s in values) if (!main.contains(s)) s];
}
