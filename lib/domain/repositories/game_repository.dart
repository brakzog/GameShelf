import '../../core/database/app_database.dart';
import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

class GameRepository {
  const GameRepository();

  Future<List<GameEntry>> getInstalledGames() async {
    final db = await AppDatabase.open();
    final rows = await db.query(
      'games',
      orderBy: 'favorite DESC, title COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => GameEntry.fromDatabaseMap(row))
        .where((game) => game.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> replaceInstalledGames(List<GameEntry> scannedGames) async {
    final db = await AppDatabase.open();
    final now = DateTime.now();

    await db.transaction((txn) async {
      final previousRows = await txn.query(
        'games',
        columns: <String>['database_id', 'favorite'],
      );
      final favorites = <String, bool>{
        for (final row in previousRows)
          row['database_id'] as String: (row['favorite'] as int? ?? 0) == 1,
      };

      await txn.delete('games');
      final batch = txn.batch();
      for (final game in scannedGames) {
        final enriched = game.copyWith(
          favorite: favorites[game.databaseId] ?? game.favorite,
          lastSeenAt: now,
        );
        batch.insert(
          'games',
          enriched.toDatabaseMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> setFavorite(GameEntry game, bool favorite) async {
    final db = await AppDatabase.open();
    await db.update(
      'games',
      <String, Object?>{'favorite': favorite ? 1 : 0},
      where: 'database_id = ?',
      whereArgs: <Object?>[game.databaseId],
    );
  }
}
