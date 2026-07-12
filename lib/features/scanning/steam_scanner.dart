import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import '../../core/utils/registry.dart';
import '../../core/utils/vdf_parser.dart';
import 'game_scanner.dart';

class SteamScanner implements LauncherScanner {
  const SteamScanner();

  @override
  Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final steamRoot = await _findSteamRoot();
    if (steamRoot == null) return [];

    final libraryRoots = await _findLibraryRoots(steamRoot);
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

  Future<String?> _findSteamRoot() async {
    final registryCandidates = <Future<String?>>[
      Registry.queryValue(r'HKCU\Software\Valve\Steam', 'SteamPath'),
      Registry.queryValue(r'HKCU\Software\Valve\Steam', 'InstallPath'),
      Registry.queryValue(
          r'HKLM\SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath'),
      Registry.queryValue(r'HKLM\SOFTWARE\Valve\Steam', 'InstallPath'),
    ];

    for (final future in registryCandidates) {
      final value = await future;
      final normalized = _normalizePath(value);
      if (normalized != null && await Directory(normalized).exists()) {
        return normalized;
      }
    }

    final env = Platform.environment;
    final fallbackCandidates = <String>[
      if (env['PROGRAMFILES(X86)'] != null)
        '${env['PROGRAMFILES(X86)']}\\Steam',
      if (env['PROGRAMFILES'] != null) '${env['PROGRAMFILES']}\\Steam',
    ];

    for (final candidate in fallbackCandidates) {
      if (await Directory(candidate).exists()) return candidate;
    }

    return null;
  }

  Future<Set<String>> _findLibraryRoots(String steamRoot) async {
    final roots = <String>{steamRoot};
    final libraryFile = File('$steamRoot\\steamapps\\libraryfolders.vdf');
    if (!await libraryFile.exists()) return roots;

    final content = await libraryFile.readAsString();
    final parsed = VdfParser.parse(content);
    final libraryFolders = parsed['libraryfolders'];
    if (libraryFolders is! Map) return roots;

    for (final entry in libraryFolders.entries) {
      final value = entry.value;

      // New Steam format: "0" { "path" "D:\\SteamLibrary" ... }
      if (value is Map) {
        final path = _normalizePath(value['path']?.toString());
        if (path != null && await Directory(path).exists()) roots.add(path);
        continue;
      }

      // Old Steam format: "1" "D:\\SteamLibrary"
      final path = _normalizePath(value?.toString());
      if (path != null && await Directory(path).exists()) roots.add(path);
    }

    return roots;
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

  String? _normalizePath(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll('/', '\\');
  }
}
