import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_discovery.dart';
import 'database_plugin.dart';
import 'sqlite_executor.dart';

/// The Database plugin, to install with `startFlocon`: the Flocon desktop app browses and queries the SQLite databases
/// of the app.
///
/// ```dart
/// await startFlocon((flocon) => flocon..install(FloconDatabase()));
/// ```
///
/// See [floconEnableDatabasePlugin] for the databases found, [floconRegisterDatabase] to add others.
class FloconDatabase extends FloconPluginFactory {
  const FloconDatabase({this.searchDirectories});

  /// The folders searched for SQLite files. The databases, documents and application support folders when null.
  final List<Directory>? searchDirectories;

  @override
  Future<void> install() => floconEnableDatabasePlugin(searchDirectories: searchDirectories);
}

/// Lets the Flocon desktop app browse and query the SQLite databases of the app. `install(FloconDatabase())` calls it.
///
/// The SQLite files of the databases folder (`sqflite`), the documents and the application support folders are shown
/// without any setup, whatever their extension. Register the databases stored elsewhere with
/// [floconRegisterDatabase]. Only the listed databases can be queried.
///
/// Call it after `Flocon.initialize()` (it does nothing before).
Future<void> floconEnableDatabasePlugin({List<Directory>? searchDirectories}) async {
  final sender = Flocon.messageSender;
  if (sender == null || Flocon.plugin<FloconDatabasePlugin>() != null) return;
  Flocon.register(FloconDatabasePlugin(
    sender: sender,
    discovery: FloconDatabaseDiscovery(() async => searchDirectories ?? await _defaultDirectories()),
    executor: FloconSqliteExecutor(databaseFactory),
  ));
}

/// Lists a database in the Flocon desktop app under [displayName]; a database already listed is renamed. The plugin must
/// be enabled with [floconEnableDatabasePlugin] first (it does nothing before).
void floconRegisterDatabase(String displayName, String path) =>
    Flocon.plugin<FloconDatabasePlugin>()?.register(FloconDatabaseFile(displayName: displayName, path: path));

/// Shows a query run by the app in the Flocon desktop app, linked to its database by its path.
///
/// Call it from the hook of your database library, for example the `QueryInterceptor` of Drift:
///
/// ```dart
/// floconLogDatabaseQuery(databasePath, 'SELECT * FROM users WHERE id = ?', [42]);
/// ```
void floconLogDatabaseQuery(String databasePath, String sqlQuery, [List<Object?> bindArgs = const []]) =>
    Flocon.plugin<FloconDatabasePlugin>()?.logQuery(FloconDatabaseFile.idOf(databasePath), sqlQuery, bindArgs);

Future<List<Directory>> _defaultDirectories() async {
  // Where the documents folder is the one of the app: Android, iOS, and the sandbox of macOS. On an unsandboxed
  // desktop it is the folder of the user, which is not scanned.
  final isAppContainer =
      Platform.isAndroid || Platform.isIOS || Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID');
  return [
    Directory(await getDatabasesPath()),
    if (isAppContainer) await getApplicationDocumentsDirectory(),
    await getApplicationSupportDirectory(),
  ];
}
