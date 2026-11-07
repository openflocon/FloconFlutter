import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flocon/flocon.dart';

import 'database_discovery.dart';
import 'database_result.dart';
import 'sqlite_executor.dart';

/// Lets the Flocon desktop app browse and query the SQLite databases of the app, and shows the queries it runs.
///
/// The desktop asks for the databases (`get_databases`) and runs queries (`query`). Only the listed databases can be
/// queried.
class FloconDatabasePlugin implements FloconPlugin {
  FloconDatabasePlugin({
    required FloconMessageSender sender,
    required FloconDatabaseDiscovery discovery,
    required FloconSqliteExecutor executor,
    DateTime Function()? now,
  })  : _sender = sender,
        _discovery = discovery,
        _executor = executor,
        _now = now ?? DateTime.now;

  static const name = 'database';
  // desktop -> app, and app -> desktop for the answers
  static const methodGetDatabases = 'get_databases';
  static const methodQuery = 'query';
  // app -> desktop
  static const methodLogQuery = 'log_query';

  final FloconMessageSender _sender;
  final FloconDatabaseDiscovery _discovery;
  final FloconSqliteExecutor _executor;
  final DateTime Function() _now;

  // by path, so that registering a file again replaces it
  final _registered = <String, FloconDatabase>{};

  // Queries can be slow: they run in order.
  Future<void> _queue = Future.value();

  @override
  String get pluginName => name;

  /// Lists a database, or renames one already listed.
  void register(FloconDatabase database) {
    _registered[database.id] = database;
    unawaited(_enqueue(_sendDatabases));
  }

  /// Shows a query run by the app, linked to its database by the database id (its absolute path).
  void logQuery(String databaseId, String sqlQuery, [List<Object?> bindArgs = const []]) {
    try {
      _sender.send(
        plugin: pluginName,
        method: methodLogQuery,
        body: jsonEncode({
          'dbId': databaseId,
          'sqlQuery': sqlQuery,
          'bindArgs': [for (final a in bindArgs) a == null ? 'null' : '$a'],
          'timestamp': _now().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {}
  }

  @override
  void onConnectedToServer() => unawaited(_enqueue(_sendDatabases));

  @override
  void onMessageReceived(FloconMessageFromServer message) => unawaited(handleMessage(message));

  /// Resolves when the request of [message] is answered.
  Future<void> handleMessage(FloconMessageFromServer message) {
    switch (message.method) {
      case methodGetDatabases:
        return _enqueue(_sendDatabases);
      case methodQuery:
        final Map<String, dynamic> request;
        try {
          request = jsonDecode(message.body) as Map<String, dynamic>;
        } catch (_) {
          return Future.value();
        }
        return _enqueue(() => _runQuery(request));
    }
    return Future.value();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _queue.then((_) async {
      try {
        await operation();
      } catch (_) {
        // a bad request must never break the app
      }
    });
    _queue = next;
    return next;
  }

  /// The discovered databases, a registered one taking the place (and the name) of the one at the same path,
  /// then the registered ones elsewhere, if their file exists.
  Future<List<FloconDatabase>> databases() async {
    final found = await _discovery.databases();
    final foundIds = {for (final d in found) d.id};
    return [
      for (final d in found) _registered[d.id] ?? d,
      for (final d in _registered.values)
        if (!foundIds.contains(d.id) && File(d.path).existsSync()) d,
    ];
  }

  Future<void> _sendDatabases() async {
    _sender.send(
      plugin: pluginName,
      method: methodGetDatabases,
      body: jsonEncode([
        for (final d in await databases()) {'id': d.id, 'name': d.displayName},
      ]),
    );
  }

  Future<void> _runQuery(Map<String, dynamic> request) async {
    final query = request['query'] as String;
    final id = FloconDatabase.idOf(request['database'] as String);
    final known = (await databases()).any((d) => d.id == id);
    final FloconDatabaseResult result = known
        ? await _executor.execute(id, query)
        : FloconErrorResult('Unknown database: ${request['database']}', query);
    _sender.send(
      plugin: pluginName,
      method: methodQuery,
      body: jsonEncode({'requestId': request['requestId'], 'result': result.toJson()}),
    );
  }
}
