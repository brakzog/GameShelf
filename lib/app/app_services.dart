import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/library/library_controller.dart';
import 'package:gameshelf/features/scanning/game_scanner.dart';
import 'package:gameshelf/features/scanning/gog_scanner.dart';
import 'package:gameshelf/features/scanning/launcher_scanner.dart';
import 'package:gameshelf/features/scanning/steam_scanner.dart';

class AppServices {
  AppServices._();

  static final GameRepository repository = const GameRepository();

  static final GameScanner scanner = GameScanner(
    scanners: const <LauncherScanner>[
      SteamScanner(),
      GogScanner(),
    ],
  );

  static LibraryController createLibraryController() {
    return LibraryController(
      repository: repository,
      scanner: scanner,
    );
  }
}
