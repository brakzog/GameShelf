import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';

import 'launcher_scanner.dart';
import 'steam/steam_filter.dart';
import 'steam/steam_installation.dart';
import 'steam/steam_manifest_reader.dart';

class SteamScanner implements LauncherScanner {
  const SteamScanner({
    SteamInstallation installation = const SteamInstallation(),
    SteamManifestReader manifestReader = const SteamManifestReader(),
    SteamFilter filter = const SteamFilter(),
  })  : _installation = installation,
        _manifestReader = manifestReader,
        _filter = filter;

  final SteamInstallation _installation;
  final SteamManifestReader _manifestReader;
  final SteamFilter _filter;

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
        if (!_filter.shouldKeep(game)) continue;
        if (!seenAppIds.add(game.id)) continue;

        games.add(game);
      }
    }

    return games;
  }
}
