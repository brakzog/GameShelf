import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _database;

  static Future<Database> open() async {
    final existing = _database;
    if (existing != null) return existing;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appData = Platform.environment['APPDATA'];
    final root = appData == null || appData.isEmpty
        ? Directory(p.join(Directory.current.path, '.gameshelf'))
        : Directory(p.join(appData, 'GameShelf'));

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    final database = await openDatabase(
      p.join(root.path, 'gameshelf.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE games (
            database_id TEXT PRIMARY KEY,
            source_id TEXT NOT NULL,
            title TEXT NOT NULL,
            launcher TEXT NOT NULL,
            install_path TEXT,
            launch_target TEXT,
            favorite INTEGER NOT NULL DEFAULT 0,
            last_seen_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_games_title ON games(title COLLATE NOCASE)',
        );
        await db.execute(
          'CREATE INDEX idx_games_launcher ON games(launcher)',
        );
      },
    );

    _database = database;
    return database;
  }
}
