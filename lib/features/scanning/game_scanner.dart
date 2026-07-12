import 'package:gameshelf/domain/models/game_entry.dart';

import 'launcher_scanner.dart';

class ScanResult {
  final List<GameEntry> games;
  final List<String> errors;

  const ScanResult({
    required this.games,
    required this.errors,
  });
}

class GameScanner {
  final List<LauncherScanner> scanners;

  const GameScanner({
    required this.scanners,
  });

  Future<ScanResult> scanAll() async {
    final games = <GameEntry>[];
    final errors = <String>[];

    for (final scanner in scanners) {
      try {
        games.addAll(await scanner.scan());
      } catch (error) {
        errors.add('${scanner.name}: $error');
      }
    }

    games.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return ScanResult(
      games: games,
      errors: errors,
    );
  }
}
