import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'launcher_scanner.dart';
import 'steam/steam_installation.dart';
import '../../core/utils/vdf_parser.dart';

class SteamScanner implements LauncherScanner {
  const SteamScanner({
    SteamInstallation installation = const SteamInstallation(),
  }) : _installation = installation;

  final SteamInstallation _installation;

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

        final game = await _readManifest(entity, root);
        if (game == null) continue;
        if (_isHiddenSteamEntry(game)) continue;
        if (!seenAppIds.add(game.id)) continue;
        games.add(game);
      }
    }

    return games;
  }

  Future<GameEntry?> _readManifest(File manifest, String libraryRoot) async {
    try {
      final content = await manifest.readAsString();
      final parsed = VdfParser.parse(content);
      final appState = parsed['AppState'];
      if (appState is! Map) return null;

      final appId = appState['appid']?.toString();
      final name = appState['name']?.toString();
      final installDir = appState['installdir']?.toString();

      if (appId == null || appId.isEmpty || name == null || name.isEmpty) {
        return null;
      }

      final installPath = installDir == null || installDir.isEmpty
          ? null
          : '$libraryRoot\\steamapps\\common\\$installDir';

      return GameEntry(
        id: appId,
        title: name,
        launcher: LauncherType.steam,
        installPath: installPath,
        launchTarget: 'steam://rungameid/$appId',
      );
    } catch (_) {
      return null;
    }
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
