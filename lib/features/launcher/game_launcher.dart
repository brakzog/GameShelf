import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:path/path.dart' as p;

class GameLauncher {
  const GameLauncher();

  Future<void> launch(GameEntry game) async {
    switch (game.launcher) {
      case LauncherType.steam:
        await Process.start(
          'cmd',
          <String>[
            '/c',
            'start',
            '',
            'steam://rungameid/${game.id}',
          ],
        );
        return;

      case LauncherType.gog:
        final target = game.launchTarget;

        if (target == null || target.trim().isEmpty) {
          throw StateError('Aucune cible de lancement trouvée');
        }

        await launchGogGame(game);
        return;

      case LauncherType.epic:
        final target = game.launchTarget;

        if (target == null || target.isEmpty) {
          throw StateError('Aucune cible de lancement trouvée');
        }

        await Process.start(
          target,
          const <String>[],
          workingDirectory: game.installPath,
        );
        return;
    }
  }

  Future<void> launchGogGame(GameEntry game) async {
    final target = game.launchTarget?.trim();

    if (target == null || target.isEmpty) {
      throw StateError(
        'Aucune cible de lancement trouvée pour ${game.title}',
      );
    }

    final normalizedTarget = p.normalize(target);
    final workingDirectory = p.dirname(normalizedTarget);

    final file = File(normalizedTarget);

    if (!await file.exists()) {
      throw FileSystemException(
        'La cible de lancement GOG est introuvable',
        normalizedTarget,
      );
    }

    await Process.start(
      'cmd.exe',
      [
        '/c',
        'start',
        '',
        normalizedTarget,
      ],
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.detached,
    );
  }
}
