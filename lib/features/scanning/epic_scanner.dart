import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';

import 'epic/epic_filter.dart';
import 'epic/epic_manifest_reader.dart';
import 'launcher_scanner.dart';

class EpicScanner implements LauncherScanner {
  const EpicScanner({
    EpicManifestReader manifestReader = const EpicManifestReader(),
    EpicFilter filter = const EpicFilter(),
  })  : _manifestReader = manifestReader,
        _filter = filter;

  final EpicManifestReader _manifestReader;
  final EpicFilter _filter;

  @override
  String get name => 'Epic Games';

  @override
  Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final manifests = await _manifestReader.readAll();
    final games = <GameEntry>[];
    final seenAppNames = <String>{};

    for (final manifest in manifests) {
      if (!_filter.shouldKeep(manifest)) continue;

      final appName = _readString(manifest, 'AppName');
      final displayName = _readString(manifest, 'DisplayName');
      final installLocation = _readString(manifest, 'InstallLocation');
      final launchExecutable = _readString(
        manifest,
        'LaunchExecutable',
      );

      if (appName.isEmpty ||
          displayName.isEmpty ||
          installLocation.isEmpty ||
          launchExecutable.isEmpty) {
        continue;
      }

      if (!seenAppNames.add(appName.toLowerCase())) {
        continue;
      }

      final executablePath = _buildExecutablePath(
        installLocation,
        launchExecutable,
      );

      games.add(
        GameEntry(
          id: appName,
          title: displayName,
          launcher: LauncherType.epic,
          installPath: installLocation,
          launchTarget: executablePath,
        ),
      );
    }

    games.sort(
      (first, second) =>
          first.title.toLowerCase().compareTo(second.title.toLowerCase()),
    );

    return games;
  }

  String _readString(Map<String, dynamic> manifest, String key) {
    final value = manifest[key];

    return value is String ? value.trim() : '';
  }

  String _buildExecutablePath(
    String installLocation,
    String launchExecutable,
  ) {
    final normalizedExecutable = launchExecutable
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);

    return [
      installLocation,
      normalizedExecutable,
    ].join(Platform.pathSeparator);
  }
}
