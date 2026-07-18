import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';

import '../../../core/utils/vdf_parser.dart';

class SteamManifestReader {
  const SteamManifestReader();

  Future<GameEntry?> read(
    File manifest,
    String libraryRoot,
  ) async {
    try {
      final content = await manifest.readAsString();
      final parsed = VdfParser.parse(content);
      final appState = parsed['AppState'];

      if (appState is! Map) {
        return null;
      }

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
}
