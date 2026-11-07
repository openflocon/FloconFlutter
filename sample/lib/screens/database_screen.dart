import 'dart:math';

import 'package:flocon_database/flocon_database.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../theme/sample_screen.dart';
import '../widgets/sample_widgets.dart';

/// `dogs.sqlite` is created on the first run and registered with Flocon: open it in Flocon > Database to run queries and
/// watch the ones logged here.
class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  static const _dogs = [('Rex', 'Labrador'), ('Milo', 'Beagle'), ('Luna', 'Poodle'), ('Rocky', 'Boxer'), ('Bella', 'Husky')];
  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final path = '${await getDatabasesPath()}/dogs.sqlite';
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('CREATE TABLE dogs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, breed TEXT NOT NULL)'),
    );
    floconRegisterDatabase('Dogs', path);
    return _db = db;
  }

  Future<String?> _insert() async {
    final db = await _open();
    final (name, breed) = _dogs[Random().nextInt(_dogs.length)];
    const sql = 'INSERT INTO dogs (name, breed) VALUES (?, ?)';
    floconLogDatabaseQuery(db.path, sql, [name, breed]);
    final id = await db.rawInsert(sql, [name, breed]);
    return '$name ($breed) → id $id';
  }

  Future<String?> _count() async {
    final db = await _open();
    const sql = 'SELECT COUNT(*) AS count FROM dogs';
    floconLogDatabaseQuery(db.path, sql);
    final rows = await db.rawQuery(sql);
    return '${rows.first['count']} dog(s)';
  }

  Future<String?> _clear() async {
    final db = await _open();
    const sql = 'DELETE FROM dogs';
    floconLogDatabaseQuery(db.path, sql);
    return '${await db.rawDelete(sql)} row(s) deleted';
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SampleScreenContainer(screen: SampleScreen.database, children: [
        SampleSection(title: 'Rows', children: [
          SampleActionRow(title: 'Dog', detail: 'Insert a dog in dogs.sqlite', buttonTitle: 'Insert', action: _insert),
          SampleActionRow(title: 'Count', detail: 'SELECT COUNT(*) FROM dogs', buttonTitle: 'Query', action: _count),
          SampleActionRow(title: 'Clear', detail: 'DELETE FROM dogs', buttonTitle: 'Delete', isDestructive: true, action: _clear),
        ]),
        const SampleInfoCard(
          'dogs.sqlite is created on the first run, in the databases folder, and registered with Flocon. The queries above are also logged: '
          'see them in Flocon > Database, next to the ones you run from the desktop.',
        ),
      ]);
}
