import '../../../domain/models/game_entry.dart';
import '../cover_provider.dart';
import '../cover_result.dart';

class SteamCoverProvider implements CoverProvider {
  const SteamCoverProvider();

  @override
  bool supports(GameEntry game) {
    return game.launcher == LauncherType.steam &&
        game.id.trim().isNotEmpty &&
        int.tryParse(game.id) != null;
  }

  @override
  Future<CoverResult> findCover(GameEntry game) async {
    final appId = game.id.trim();

    return CoverResult.remote(
      Uri.https(
        'cdn.cloudflare.steamstatic.com',
        '/steam/apps/$appId/library_600x900.jpg',
      ),
    );
  }
}
