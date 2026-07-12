import 'package:gameshelf/domain/models/game_entry.dart';
import 'gog_scanner.dart';
import 'steam_scanner.dart';

class ScanResult {
  final List<GameEntry> games;
  final List<String> errors;

  const ScanResult({required this.games, required this.errors});
}

abstract interface class LauncherScanner {
  Future<List<GameEntry>> scan();
}

class GameScanner {
  const GameScanner._();

  static Future<ScanResult> scanAll() async {
    final games = <GameEntry>[];
    final errors = <String>[];

    try {
      games.addAll(await SteamScanner.scan());
    } catch (error) {
      errors.add('Steam: $error');
    }

    try {
      games.addAll(await GogScanner.scan());
    } catch (error) {
      errors.add('GOG: $error');
    }

    games
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return ScanResult(games: games, errors: errors);
  }
}
