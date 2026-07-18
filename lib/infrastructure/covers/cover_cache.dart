import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:path/path.dart' as p;

class CoverCache {
  const CoverCache();

  Future<Directory> getRootDirectory() async {
    final appData = Platform.environment['APPDATA'];

    final root = appData == null || appData.isEmpty
        ? Directory(
            p.join(
              Directory.current.path,
              '.gameshelf',
              'covers',
            ),
          )
        : Directory(
            p.join(
              appData,
              'GameShelf',
              'covers',
            ),
          );

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return root;
  }

  Future<String> getCoverPath(
    GameEntry game, {
    String extension = 'jpg',
  }) async {
    final root = await getRootDirectory();

    final safeId = _sanitize(game.id);

    return p.join(
      root.path,
      '${game.launcher.name}_$safeId.$extension',
    );
  }

  Future<bool> exists(GameEntry game) async {
    final file = await getFile(game);
    return file.exists();
  }

  String _sanitize(String value) {
    return value.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
  }

  Future<File> getFile(GameEntry game) async {
    return File(await getCoverPath(game));
  }

  Future<void> delete(GameEntry game) async {
    final file = await getFile(game);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clear() async {
    final root = await getRootDirectory();

    if (!await root.exists()) {
      return;
    }

    await for (final entity in root.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}
