import 'dart:convert';
import 'dart:io';

import '../models/game_entry.dart';

class LibraryCache {
  const LibraryCache._();

  static Future<File> _cacheFile() async {
    final appData = Platform.environment['APPDATA'];
    final root = appData == null || appData.isEmpty
        ? Directory('${Directory.current.path}\\.gameshelf')
        : Directory('$appData\\GameShelf');

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return File('${root.path}\\library_cache.json');
  }

  static Future<List<GameEntry>> load() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return [];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return [];
      final games = decoded['games'];
      if (games is! List) return [];

      return games
          .whereType<Map>()
          .map((item) => GameEntry.fromJson(Map<String, Object?>.from(item)))
          .where((game) => game.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<GameEntry> games) async {
    final file = await _cacheFile();
    final temporaryFile = File('${file.path}.tmp');
    final payload = <String, Object?>{
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'games': games.map((game) => game.toJson()).toList(),
    };

    await temporaryFile.writeAsString(jsonEncode(payload), flush: true);
    if (await file.exists()) await file.delete();
    await temporaryFile.rename(file.path);
  }
}
