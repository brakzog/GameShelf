import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';

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

        if (target == null || target.isEmpty) {
          throw StateError('Aucune cible de lancement trouvée');
        }

        await Process.start(
          target,
          const <String>[],
          workingDirectory: game.installPath,
        );

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
}
