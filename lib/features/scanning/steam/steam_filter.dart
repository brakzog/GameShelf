import 'package:gameshelf/domain/models/game_entry.dart';

class SteamFilter {
  const SteamFilter();

  bool shouldKeep(GameEntry game) {
    return !_isHiddenSteamEntry(game);
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
