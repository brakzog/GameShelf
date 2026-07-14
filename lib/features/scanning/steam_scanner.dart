import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'launcher_scanner.dart';
import 'steam/steam_installation.dart';
import 'steam/steam_manifest_reader.dart';

class SteamScanner implements LauncherScanner {
  const SteamScanner({
    SteamInstallation installation = const SteamInstallation(),
    SteamManifestReader manifestReader = const SteamManifestReader(),
  })  : _installation = installation,
        _manifestReader = manifestReader;

  final SteamInstallation _installation;
  final SteamManifestReader _manifestReader;

  @override
  String get name => 'Steam';

  @override
  Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final steamRoot = await _installation.findSteamRoot();
    if (steamRoot == null) return [];

    final libraryRoots = await _installation.findLibraryRoots(steamRoot);
    final games = <GameEntry>[];
    final seenAppIds = <String>{};

    for (final root in libraryRoots) {
      final steamApps = Directory('$root\\steamapps');
      if (!await steamApps.exists()) continue;

      await for (final entity in steamApps.list(followLinks: false)) {
        if (entity is! File) continue;

        final filename = entity.uri.pathSegments.last.toLowerCase();
        if (!filename.startsWith('appmanifest_') ||
            !filename.endsWith('.acf')) {
          continue;
        }

        final game = await _manifestReader.read(entity, root);
        if (game == null) continue;
        if (_isHiddenSteamEntry(game)) continue;
        if (!seenAppIds.add(game.id)) continue;
        games.add(game);
      }
    }

    return games;
  }

  bool _isHiddenSteamEntry(GameEntry game) {
    const hiddenAppIds = <String>{
      '228980', // Steamworks Common Redistributables
      '250820', // SteamVR
    };

    if (hiddenAppIds.contains(game.id)) return true;

    final title = game.title.toLowerCase();
    const hiddenTitleParts = <String>[
      'steamworks common redistributables',
      'steam linux runtime',
      'proton ',
      'dedicated server',
      'sdk',
      'driver updater',
    ];

    return hiddenTitleParts.any(title.contains);
  }
}
